import consumer from "channels/consumer"


class ChatManager {
  constructor() {
    this.chatSubscription = null;
    this.currentUserId = null;
    this.chatContainer = null;
    this.chatId = null;
    this.isInitialized = false;
  }

  // Récupérer l'ID de l'utilisateur actuel
  getCurrentUserId() {
    const metaTag = document.querySelector('meta[name="current-user-id"]');
    return metaTag ? parseInt(metaTag.content) : null;
  }

  // Appliquer les classes CSS selon l'utilisateur
  applyMessageStyles(messageElement, isCurrentUser) {
    messageElement.classList.remove('message-sent', 'message-received');

    if (isCurrentUser) {
      messageElement.classList.add('message-sent');
    } else {
      messageElement.classList.add('message-received');
    }
  }

  // Fonction pour initialiser tous les messages existants
  initializeMessageStyles() {
    if (this.chatContainer && this.currentUserId !== null) {
      const existingMessages = this.chatContainer.querySelectorAll('.message');
      existingMessages.forEach(message => {
        const messageUserId = parseInt(message.dataset.messageUserId);
        const isCurrentUser = messageUserId === this.currentUserId;
        this.applyMessageStyles(message, isCurrentUser);
      });
    }
  }

  scrollToBottom() {
    if (this.chatContainer) {
      setTimeout(() => {
        this.chatContainer.scrollTop = this.chatContainer.scrollHeight;
      }, 100);
    }
  }

  // Vérifier si tous les éléments sont prêts
  checkElementsReady() {
    this.chatContainer = document.getElementById('chat-messages');
    this.chatId = this.chatContainer?.dataset.chatId;
    this.currentUserId = this.getCurrentUserId();

    const isReady = this.chatContainer && this.chatId && this.currentUserId !== null;

    if (isReady) {
      console.log("✅ All elements ready - chatId:", this.chatId, "userId:", this.currentUserId);
    } else {
      console.log("⏳ Elements not ready - container:", !!this.chatContainer, "chatId:", this.chatId, "userId:", this.currentUserId);
    }

    return isReady;
  }

  initializeChat() {
    // Éviter les initialisations multiples
    if (this.isInitialized) {
      console.log("🔄 Chat already initialized, skipping...");
      return;
    }

    // Vérifier que tous les éléments sont prêts
    if (!this.checkElementsReady()) {
      console.log("⏳ Retrying initialization in 200ms...");
      setTimeout(() => this.initializeChat(), 200);
      return;
    }

    console.log("🚀 Initializing chat...");

    // Nettoyer l'ancienne subscription si elle existe
    this.cleanup();

    // Créer la nouvelle subscription
    this.chatSubscription = consumer.subscriptions.create(
      { channel: "ChatChannel", chat_id: this.chatId },
      {
        connected: () => {
          console.log("✅ Connected to ChatChannel for chat " + this.chatId);
          this.isInitialized = true;
          setTimeout(() => {
            this.initializeMessageStyles();
            this.scrollToBottom();
          }, 100);
        },

        disconnected: () => {
          console.log("❌ Disconnected from ChatChannel");
          this.isInitialized = false;
        },

        received: (data) => {
          console.log("📨 Received message:", data);
          if (this.chatContainer && data.message) {
            this.chatContainer.insertAdjacentHTML('beforeend', data.message);


            // Appliquer les styles au nouveau message
            const messages = this.chatContainer.querySelectorAll('.message');
            const newMessage = messages[messages.length - 1];

            if (newMessage) {
              const messageUserId = parseInt(newMessage.dataset.messageUserId);
              const isCurrentUser = messageUserId === this.currentUserId;
              this.applyMessageStyles(newMessage, isCurrentUser);
            }

            this.scrollToBottom();

          }
        }
      }
    );

    // Initialiser les styles des messages existants
    setTimeout(() => {

      this.initializeMessageStyles();
      this.scrollToBottom();
    }, 100);
  }

  cleanup() {
    if (this.chatSubscription) {
      console.log("🧹 Cleaning up chat subscription");
      consumer.subscriptions.remove(this.chatSubscription);
      this.chatSubscription = null;
    }
    this.isInitialized = false;
  }

  // Réappliquer les styles (pour les pages restaurées depuis le cache)
  refreshStyles() {
    if (this.checkElementsReady()) {
      this.initializeMessageStyles();
    }
  }
}

// Instance globale du gestionnaire de chat
const chatManager = new ChatManager();


// Événements d'initialisation - un seul point d'entrée
document.addEventListener('turbo:load', () => {
  console.log("🔄 turbo:load - initializing chat");
  chatManager.initializeChat();
});

// Nettoyage avant cache
document.addEventListener('turbo:before-cache', () => {
  console.log("🧹 turbo:before-cache - cleaning up");
  chatManager.cleanup();
});

// Fallback pour les pages sans Turbo
document.addEventListener('DOMContentLoaded', () => {
  console.log("🔄 DOMContentLoaded - initializing chat");
  // Petit délai pour s'assurer que tout est chargé
  setTimeout(() => chatManager.initializeChat(), 100);
});


// Réappliquer les styles si la page est restaurée depuis le cache
window.addEventListener('pageshow', (event) => {
  if (event.persisted) {
    console.log("🔄 pageshow (persisted) - refreshing styles");
    setTimeout(() => chatManager.refreshStyles(), 200);
  }
});

// Export pour debugging si nécessaire
window.chatManager = chatManager;
