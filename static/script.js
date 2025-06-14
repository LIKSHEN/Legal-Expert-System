document.addEventListener('DOMContentLoaded', function() {
    console.log("Chat script initializing...");

    // --- 1. GET ELEMENTS & CSRF TOKEN ---
    const chatMessages = document.getElementById('chatMessages');
    const userInput = document.getElementById('userInput');
    const sendButton = document.getElementById('sendButton');
    const clearChatButton = document.getElementById('clearChatButton');
    const csrftoken = document.querySelector('[name=csrfmiddlewaretoken]')?.value;

    // --- Sanity checks ---
    if (!chatMessages || !userInput || !sendButton || !clearChatButton) {
        console.error("Critical Error: A required chat element is missing from the page.");
        return;
    }
    if (!csrftoken) {
        console.error("Critical Error: CSRF token not found. Cannot send messages.");
        return;
    }
    console.log("All chat elements and CSRF token found.");

    // --- 2. STATE MANAGEMENT ---
    let messageHistory = [];

    // --- 3. HELPER FUNCTIONS ---
    function getCurrentTime() {
        return new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    }

    function addMessage(text, type = 'system', isLoading = false) {
        const messageDiv = document.createElement('div');
        messageDiv.className = `message ${type}`;

        const iconDiv = document.createElement('div');
        iconDiv.className = 'message-icon';
        iconDiv.innerHTML = `<i class="fas ${type === 'user' ? 'fa-user' : 'fa-user-tie'}"></i>`;

        const contentDiv = document.createElement('div');
        contentDiv.className = 'message-content';
        
        if (isLoading) {
            contentDiv.innerHTML = '<div class="loading-dots"><span></span><span></span><span></span></div>';
        } else {
            let mainText = text;
            const sources = [];
            
            // Use matchAll to find all source citations, which handles multiple sources robustly.
            const sourceRegex = /Source:\s*`([\s\S]+?)`/g;
            const matches = Array.from(text.matchAll(sourceRegex));

            if (matches.length > 0) {
                // The main text is everything before the first source citation
                mainText = text.substring(0, matches[0].index).trim();
                
                // Extract the source text from each match
                matches.forEach(match => {
                    sources.push(match[1]);
                });
            }

            const textP = document.createElement('p');
            textP.textContent = mainText;
            contentDiv.appendChild(textP);

            // If there are sources, create containers for them
            if (sources.length > 0) {
                sources.forEach(sourceText => {
                    const sourceContainer = document.createElement('div');
                    sourceContainer.className = 'source-container';
                    sourceContainer.innerHTML = `<p class="source-title">Based on:</p><pre><code>${sourceText.trim()}</code></pre>`;
                    contentDiv.appendChild(sourceContainer);
                });
            }

            const timestampSpan = document.createElement('span');
            timestampSpan.className = 'timestamp';
            timestampSpan.textContent = getCurrentTime();
            contentDiv.appendChild(timestampSpan);

            // Add to history only if it's not a loading message
            messageHistory.push({ isUser: type === 'user', text: text });
        }

        messageDiv.appendChild(iconDiv);
        messageDiv.appendChild(contentDiv);
        chatMessages.appendChild(messageDiv);
        chatMessages.scrollTop = chatMessages.scrollHeight; // Auto-scroll
        return messageDiv;
    }

    // --- 4. API COMMUNICATION ---
    async function getBotResponse(userMessage) {
        console.log("Sending to backend. History length:", messageHistory.length);
        try {
            const response = await fetch('/api/chat/', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRFToken': csrftoken
                },
                body: JSON.stringify({
                    message: userMessage,
                    chat_history: messageHistory.slice(0, -1) // Send history *before* the current user message
                })
            });

            if (!response.ok) {
                const errorText = await response.text();
                throw new Error(`Server returned an error: ${response.status} - ${errorText}`);
            }

            const data = await response.json();
            if (!data.success) {
                throw new Error(data.error || 'Server indicated failure but sent no error message.');
            }
            return data.response;
        } catch (error) {
            console.error("Error fetching bot response:", error);
            throw error; // Propagate error to be handled by the caller
        }
    }

    // --- 5. CORE LOGIC ---
    async function handleSendMessage() {
        const messageText = userInput.value.trim();
        if (!messageText) return;

        // Add user message to UI and history
        addMessage(messageText, 'user');
        const currentUserMessage = messageText; // store before clearing
        userInput.value = '';
        userInput.style.height = 'auto';

        // Show loading indicator
        const loadingMessageElement = addMessage('', 'system', true);

        try {
            const botResponse = await getBotResponse(currentUserMessage);
            addMessage(botResponse, 'system');
        } catch (error) {
            // The error is already logged by getBotResponse
            addMessage("I am having trouble connecting to my knowledge base right now. Please try again in a moment.", 'system');
        } finally {
            // Always remove the loading indicator
            loadingMessageElement.remove();
            // Remove the loading message from history
            messageHistory.pop();
        }
    }

    // --- 6. EVENT LISTENERS ---
    sendButton.addEventListener('click', handleSendMessage);
    userInput.addEventListener('keypress', (e) => {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            handleSendMessage();
        }
    });

    clearChatButton.addEventListener('click', () => {
        chatMessages.innerHTML = '';
        messageHistory = [];
        addMessage("Chat cleared. How can I help you?", 'system');
    });

    userInput.addEventListener('input', () => {
        userInput.style.height = 'auto';
        userInput.style.height = Math.min(userInput.scrollHeight, 120) + 'px';
    });

    // --- 7. INITIALIZATION ---
    userInput.focus();
    console.log("Chat script fully initialized and ready.");
}); 