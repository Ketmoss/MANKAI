import consumer from "channels/consumer"

let chatSubscription = null;

// Récupérer l'ID de l'utilisateur actuel
function getCurrentUserId() {
  const metaTag = document.querySelector('meta[name="current-user-id"]');
  return metaTag ? parseInt(metaTag.content) : null;
}

// Appliquer les classes CSS selon l'utilisateur
function applyMessageStyles(messageElement, isCurrentUser) {
  messageElement.classList.remove('message-sent', 'message-received');

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

function scrollToBottom() {
  const chatContainer = document.getElementById('chat-messages');
  if (chatContainer) {
    setTimeout(() => {
      chatContainer.scrollTop = chatContainer.scrollHeight;
    }, 100);
  }
}

function initializeChat() {
  const chatContainer = document.getElementById('chat-messages');
  const chatId = chatContainer?.dataset.chatId;
  const currentUserId = getCurrentUserId();

  console.log("Initializing chat, chatId:", chatId, "userId:", currentUserId);

  // Nettoyer l'ancienne subscription si elle existe
  if (chatSubscription) {
    consumer.subscriptions.remove(chatSubscription);
    chatSubscription = null;
  }

  if (chatId && currentUserId !== null) {
    chatSubscription = consumer.subscriptions.create(
      { channel: "ChatChannel", chat_id: chatId },
      {
        connected() {
          console.log("✅ Connected to ChatChannel for chat " + chatId);
          setTimeout(() => {
            initializeMessageStyles();
            scrollToBottom();
          }, 100);
        },

        disconnected() {
          console.log("❌ Disconnected from ChatChannel");
        },

        received(data) {
          console.log("📨 Received message:", data);
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

            scrollToBottom();
          }
        }
      }
    );

    // Initialiser les styles au chargement
    setTimeout(() => {
      initializeMessageStyles();
      scrollToBottom();
    }, 100);
  }
}

function cleanupChat() {
  if (chatSubscription) {
    consumer.subscriptions.remove(chatSubscription);
    chatSubscription = null;
  }
}

// Événements Turbo (pour Rails 7)
document.addEventListener('turbo:load', initializeChat);
document.addEventListener('turbo:before-cache', cleanupChat);

// Fallback pour le premier chargement (au cas où)
document.addEventListener('DOMContentLoaded', initializeChat);

// Réappliquer les styles si la page est restaurée depuis le cache
window.addEventListener('pageshow', function(event) {
  if (event.persisted) {
    setTimeout(initializeMessageStyles, 200);
  }
});
