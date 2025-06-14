from django.shortcuts import render
from django.http import JsonResponse
from django.core.files.storage import FileSystemStorage
from django.views.decorators.csrf import ensure_csrf_cookie
from django.views.decorators.http import require_http_methods
import os
import re
import json
import requests
from dotenv import load_dotenv
import logging

# Set up logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()

# NEW: RAG-based System Prompt
RAG_SYSTEM_PROMPT = """You are a highly specialized legal assistant AI. Your sole purpose is to answer questions based *exclusively* on the provided knowledge base context.

**Your Strict Instructions:**
1.  **Single Source of Truth:** The ONLY information you can use to answer a question is the text provided in the "KNOWLEDGE BASE CONTEXT" section below. You must not use any external knowledge or prior training.
2.  **Strict Relevance Check:** If a user's question cannot be answered using the provided context, you MUST respond with: "I'm sorry, but my knowledge is limited to the Law Reform (Marriage and Divorce) Act 1976 as contained in my knowledge base. I cannot answer questions outside of this specific scope." Do not attempt to guess, infer, or provide related information.
3.  **Answering Style:** When you can answer a question, synthesize the information directly from the context. You can rephrase it to be more user-friendly, but you must not add any information that is not explicitly present in the text.
4.  **Cite Your Source:** After providing your main answer, you MUST cite the source rule(s). For EACH rule you use, add it on a **new line** starting with the prefix `Source:` followed by the rule enclosed in backticks.
    *Example for one source:*
    This is the answer.
    Source: `rule1(...).`
    *Example for two sources:*
    This is the answer.
    Source: `rule1(...).`
    Source: `rule2(...).`
5.  **No General Conversation:** Do not engage in casual conversation. If the user says "hello," asks about your identity, or makes small talk, you must politely state your purpose. A correct response would be: "I am a legal assistant AI with knowledge based on the Law Reform (Marriage and Divorce) Act 1976. How can I help you with a question about this act?"

**KNOWLEDGE BASE CONTEXT:**
---
{knowledge_base_content}
---
"""

@ensure_csrf_cookie
def home(request):
    return render(request, 'home.html')

def knowledge_base(request):
    prolog_file_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'legalexpertsystem', 'Knowledge_Base_for_Non-Muslim_Family_Law.pl')
    facts_and_rules = parse_prolog_file(prolog_file_path)
    
    if request.method == 'POST' and request.FILES.get('prolog_file'):
        uploaded_file = request.FILES['prolog_file']
        fs = FileSystemStorage()
        filename = fs.save('uploaded_prolog_files/' + uploaded_file.name, uploaded_file)
        uploaded_file_path = fs.path(filename)
        facts_and_rules = parse_prolog_file(uploaded_file_path)
        return JsonResponse({'facts_and_rules': facts_and_rules})
    
    return render(request, 'knowledge_base.html', {'facts_and_rules': facts_and_rules})

def parse_prolog_file(file_path):
    facts_and_rules = {
        'facts': [],
        'rules': [],
        'sections': {}
    }
    current_section = None
    
    with open(file_path, 'r', encoding='utf-8') as file:
        content = file.read()
        
        # Extract sections
        sections = re.findall(r'% -{3,}\n% (PART [^%]+)\n% -{3,}', content)
        for section in sections:
            facts_and_rules['sections'][section] = {
                'facts': [],
                'rules': []
            }
        
        # Process line by line
        for line in content.split('\n'):
            line = line.strip()
            
            # Skip empty lines and comments
            if not line or line.startswith('%'):
                # Check if this is a section header
                if line.startswith('% PART'):
                    current_section = line[2:].strip()
                continue
            
            # Remove comments at the end of lines
            line = re.sub(r'\s*%.*$', '', line)
            
            # Facts end with a period
            if line.endswith('.') and ':-' not in line:
                fact = line[:-1]  # Remove the period
                facts_and_rules['facts'].append(fact)
                if current_section and current_section in facts_and_rules['sections']:
                    facts_and_rules['sections'][current_section]['facts'].append(fact)
            
            # Rules contain ':-'
            elif ':-' in line:
                rule = line.rstrip('.')
                facts_and_rules['rules'].append(rule)
                if current_section and current_section in facts_and_rules['sections']:
                    facts_and_rules['sections'][current_section]['rules'].append(rule)
    
    return facts_and_rules

@require_http_methods(["POST"])
def chat_with_gemini(request):
    try:
        logger.debug("Received RAG chat request")
        
        # 1. Load the knowledge base content
        try:
            prolog_file_path = os.path.join(os.path.dirname(__file__), 'Knowledge_Base_for_Non-Muslim_Family_Law.pl')
            with open(prolog_file_path, 'r', encoding='utf-8') as f:
                knowledge_base_content = f.read()
        except FileNotFoundError:
            logger.error("Knowledge base file not found!")
            return JsonResponse({'error': 'Internal configuration error: Knowledge base not found.', 'success': False}, status=500)
        
        # 2. Parse incoming data
        data = json.loads(request.body)
        user_message = data.get('message', '')
        chat_history = data.get('chat_history', [])
        
        # 3. Get API Key
        api_key = os.getenv('GEMINI_API_KEY')
        if not api_key:
            logger.error("Gemini API key not found in environment variables")
            return JsonResponse({'error': 'Gemini API key not configured', 'success': False}, status=500)

        # 4. Construct the RAG prompt
        contextual_system_prompt = RAG_SYSTEM_PROMPT.format(knowledge_base_content=knowledge_base_content)
        
        limited_history = chat_history[-10:] if len(chat_history) > 10 else chat_history
        conversation_history = "\n".join([f"{'User' if msg['isUser'] else 'Assistant'}: {msg['text']}" for msg in limited_history])
        
        full_prompt = f"{contextual_system_prompt}\n\nPrevious conversation:\n{conversation_history}\n\nUser: {user_message}\nAssistant:"
        
        logger.debug("Constructed RAG prompt for Gemini.")

        # 5. Call Gemini API
        response = call_gemini_api(full_prompt, api_key)
        
        return JsonResponse({
            'response': response,
            'success': True
        })
        
    except json.JSONDecodeError as e:
        logger.error(f"JSON decode error: {e}")
        return JsonResponse({'error': 'Invalid JSON in request body', 'success': False}, status=400)
    except Exception as e:
        logger.error(f"Unexpected error in chat_with_gemini: {e}", exc_info=True)
        return JsonResponse({'error': str(e), 'success': False}, status=500)

def call_gemini_api(prompt, api_key):
    try:
        url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key={api_key}"
        
        headers = {
            'Content-Type': 'application/json',
        }
        
        data = {
            "contents": [{
                "parts": [{
                    "text": prompt
                }]
            }]
        }
        
        logger.debug(f"Sending request to Gemini API.")
        response = requests.post(url, headers=headers, json=data)
        
        if response.status_code == 200:
            response_data = response.json()
            if (response_data.get('candidates') and 
                response_data['candidates'][0].get('content') and 
                response_data['candidates'][0]['content'].get('parts') and 
                response_data['candidates'][0]['content']['parts'][0].get('text')):
                return response_data['candidates'][0]['content']['parts'][0]['text'].strip()
            else:
                logger.error("Could not parse Gemini API response")
                return "Error: Could not parse response from API"
        else:
            error_message = f"Gemini API request failed with status {response.status_code}"
            if response.text:
                try:
                    error_data = response.json()
                    error_message += f": {json.dumps(error_data)}"
                except:
                    error_message += f": {response.text}"
            logger.error(error_message)
            return f"Error: {error_message}"
            
    except Exception as e:
        logger.error(f"Error calling Gemini API: {e}", exc_info=True)
        return f"Error: Failed to connect to API. {str(e)}"
