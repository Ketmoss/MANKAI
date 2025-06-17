import consumer from "channels/consumer"

// Récupérer l'ID de l'utilisateur actuel
function getCurrentUserId() {
  const metaTag = document.querySelector('meta[name="current-user-id"]');
  return metaTag ? parseInt(metaTag.content) : null;
}

// Appliquer les classes CSS selon l'utilisateur
function applyMessageStyles(messageElement, isCurrentUser) {
  // Supprimer les anciennes classes
  messageElement.classList.remove('message-sent', 'message-received');

  // Ajouter la nouvelle classe
  if (isCurrentUser) {
    messageElement.classList.add('message-sent');
  } else {
    messageElement.classList.add('message-received');
  }
}

// Fonction pour initialiser tous les messages
function initializeMessageStyles() {
  const chatContainer = document.getElementById('chat-messages');
  const currentUserId = getCurrentUserId();

  if (chatContainer && currentUserId !== null) {
    const existingMessages = chatContainer.querySelectorAll('.message');
    existingMessages.forEach(message => {
      const messageUserId = parseInt(message.dataset.messageUserId);
      const isCurrentUser = messageUserId === currentUserId;
      applyMessageStyles(message, isCurrentUser);
    });
  }
}

document.addEventListener('DOMContentLoaded', function() {
  const chatContainer = document.getElementById('chat-messages');
  const chatId = chatContainer?.dataset.chatId;
  const currentUserId = getCurrentUserId();

  if (chatId && currentUserId !== null) {
    const subscription = consumer.subscriptions.create(
      { channel: "ChatChannel", chat_id: chatId },
      {
        connected() {
          console.log("Connected to ChatChannel for chat " + chatId);
          // Appliquer les styles à la connexion
          setTimeout(() => {
            initializeMessageStyles();
            this.scrollToBottom();
          }, 100);
        },

        disconnected() {
          console.log("Disconnected from ChatChannel");
        },

        received(data) {
          console.log("Received message:", data);
          if (chatContainer && data.message) {
            chatContainer.insertAdjacentHTML('beforeend', data.message);

            // Appliquer les styles au nouveau message
            const messages = chatContainer.querySelectorAll('.message');
            const newMessage = messages[messages.length - 1];

            if (newMessage) {
              const messageUserId = parseInt(newMessage.dataset.messageUserId);
              const isCurrentUser = messageUserId === currentUserId;
              applyMessageStyles(newMessage, isCurrentUser);
            }

            this.scrollToBottom();
          }
        },

        scrollToBottom() {
          if (chatContainer) {
            setTimeout(() => {
              chatContainer.scrollTop = chatContainer.scrollHeight;
            }, 100);
          }
        }
      }
    );

    // Initialiser les styles au chargement
    setTimeout(() => {
      initializeMessageStyles();

      // Scroll initial
      if (chatContainer) {
        chatContainer.scrollTop = chatContainer.scrollHeight;
      }
    }, 100);
  }
});

// Réappliquer les styles si la page est restaurée depuis le cache
window.addEventListener('pageshow', function(event) {
  if (event.persisted) {
    setTimeout(initializeMessageStyles, 200);
  }
});
