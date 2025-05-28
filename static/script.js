document.addEventListener('DOMContentLoaded', () => {
    const chatMessages = document.getElementById('chatMessages');
    const userInput = document.getElementById('userInput');
    const sendButton = document.getElementById('sendButton');
    const clearChatButton = document.getElementById('clearChatButton');

    // Function to get current time for timestamp
    function getCurrentTime() {
        return new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    }

    // Function to add a message to the chat
    function addMessage(text, type = 'system', isLoading = false) {
        const messageDiv = document.createElement('div');
        messageDiv.className = `message ${type}`;

        const iconDiv = document.createElement('div');
        iconDiv.className = 'message-icon';
        const icon = document.createElement('i');
        icon.className = `fas ${type === 'user' ? 'fa-user-tie' : 'fa-robot'}`;
        iconDiv.appendChild(icon);

        const contentDiv = document.createElement('div');
        contentDiv.className = 'message-content';
        
        if (isLoading) {
            const loadingDots = document.createElement('div');
            loadingDots.className = 'loading-dots';
            for (let i = 0; i < 3; i++) {
                loadingDots.appendChild(document.createElement('span'));
            }
            contentDiv.appendChild(loadingDots);
        } else {
            const textP = document.createElement('p');
            textP.textContent = text;
            contentDiv.appendChild(textP);

            const timestampSpan = document.createElement('span');
            timestampSpan.className = 'timestamp';
            timestampSpan.textContent = getCurrentTime();
            contentDiv.appendChild(timestampSpan);
        }

        messageDiv.appendChild(iconDiv);
        messageDiv.appendChild(contentDiv);
        chatMessages.appendChild(messageDiv);
        chatMessages.scrollTop = chatMessages.scrollHeight;
        return messageDiv; // Return the message element for potential updates (e.g., loading state)
    }

    // Function to simulate API call and get bot response
    async function getBotResponse(userMessage) {
        // Simulate API call delay
        await new Promise(resolve => setTimeout(resolve, 1000 + Math.random() * 1000));

        // In a real application, this would be a fetch call to your Django backend
        // For now, a simple rule-based mock response
        if (userMessage.toLowerCase().includes('hello') || userMessage.toLowerCase().includes('hi')) {
            return "Hello there! How can I assist you with legal matters today?";
        } else if (userMessage.toLowerCase().includes('contract')) {
            return "Certainly. Contract law can be complex. Could you specify what aspect of contract law you're interested in? For example, formation, breach, or specific clauses?";
        } else if (userMessage.toLowerCase().includes('divorce')) {
            return "I understand. Matters of family law like divorce require careful consideration. While I can provide general information, it's best to consult with a qualified legal professional for advice specific to your situation.";
        } else if (userMessage.toLowerCase().includes('thank')) {
            return "You're welcome! Feel free to ask if you have more questions.";
        }
        return "I'm here to help with general legal information. Please phrase your query clearly.";
    }

    // Function to handle sending messages
    async function handleSendMessage() {
        const messageText = userInput.value.trim();
        if (!messageText) return;

        addMessage(messageText, 'user');
        userInput.value = '';
        userInput.style.height = 'auto'; // Reset height

        const loadingMessageElement = addMessage('', 'system', true);

        try {
            // const response = await fetch('/api/query', { // Your actual API endpoint
            //     method: 'POST',
            //     headers: {
            //         'Content-Type': 'application/json',
            //         'X-CSRFToken': getCookie('csrftoken') // Important for Django POST requests
            //     },
            //     body: JSON.stringify({ query: messageText })
            // });
            // if (!response.ok) {
            //     throw new Error('Network response was not ok');
            // }
            // const data = await response.json();
            // const botResponse = data.response; 

            const botResponse = await getBotResponse(messageText); // Using mocked response
            
            // Update loading message with actual response
            loadingMessageElement.remove(); // Remove the loading dots message
            addMessage(botResponse, 'system');

        } catch (error) {
            loadingMessageElement.remove();
            addMessage("I apologize, but I'm having trouble connecting to the legal knowledge base. Please try again later.", 'system');
            console.error('Error:', error);
        }
    }

    // Event listeners
    sendButton.addEventListener('click', handleSendMessage);
    userInput.addEventListener('keypress', (e) => {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            handleSendMessage();
        }
    });

    clearChatButton.addEventListener('click', () => {
        chatMessages.innerHTML = ''; // Clear messages
        addMessage("Chat cleared. How can I assist you further?", 'system'); // Add a system message
    });

    // Auto-resize textarea
    userInput.addEventListener('input', () => {
        userInput.style.height = 'auto';
        userInput.style.height = Math.min(userInput.scrollHeight, 120) + 'px'; // Max height 120px
    });

    // Function to get CSRF token (important for Django POST requests if you implement the backend)
    // function getCookie(name) {
    //     let cookieValue = null;
    //     if (document.cookie && document.cookie !== '') {
    //         const cookies = document.cookie.split(';');
    //         for (let i = 0; i < cookies.length; i++) {
    //             const cookie = cookies[i].trim();
    //             if (cookie.substring(0, name.length + 1) === (name + '=')) {
    //                 cookieValue = decodeURIComponent(cookie.substring(name.length + 1));
    //                 break;
    //             }
    //         }
    //     }
    //     return cookieValue;
    // }

    // Initial welcome message focus
    userInput.focus();
}); 