import consumer from "channels/consumer"

class ChatManager {
  constructor() {
    this.chatSubscription = null;
    this.currentUserId = null;
    this.chatContainer = null;
    this.chatId = null;
    this.isInitialized = false;
    this.messageForm = null;
    this.messageInput = null;
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

  // Vider le formulaire de saisie
  clearMessageForm() {
    if (this.messageInput) {
      this.messageInput.value = '';
      this.messageInput.focus(); // Remettre le focus sur le champ
    }
  }

  // Gérer la soumission du formulaire
  handleFormSubmission() {
    if (this.messageForm) {
      this.messageForm.addEventListener('submit', (event) => {
        // Ne pas empêcher la soumission, mais vider le champ après
        setTimeout(() => {
          this.clearMessageForm();
        }, 50); // Petit délai pour s'assurer que la soumission est traitée
      });

      // Alternative : écouter les événements AJAX si vous utilisez des requêtes AJAX
      this.messageForm.addEventListener('ajax:success', () => {
        this.clearMessageForm();
      });

      // Pour les requêtes Turbo (Rails 7)
      this.messageForm.addEventListener('turbo:submit-end', (event) => {
        if (event.detail.success) {
          this.clearMessageForm();
        }
      });
    }
  }

  // Vérifier si tous les éléments sont prêts
  checkElementsReady() {
    this.chatContainer = document.getElementById('chat-messages');
    this.chatId = this.chatContainer?.dataset.chatId;
    this.currentUserId = this.getCurrentUserId();

    // Récupérer le formulaire et le champ de saisie
    this.messageForm = document.querySelector('#new_message, form[data-chat-form], .message-form');
    this.messageInput = document.querySelector('#message_content, input[name="message[content]"], textarea[name="message[content]"]');

    const isReady = this.chatContainer && this.chatId && this.currentUserId !== null;

    if (isReady) {
      console.log("✅ All elements ready - chatId:", this.chatId, "userId:", this.currentUserId);
      console.log("📝 Form elements - form:", !!this.messageForm, "input:", !!this.messageInput);
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

    // Initialiser la gestion du formulaire
    this.handleFormSubmission();

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

              // Si c'est notre propre message, vider le formulaire
              if (isCurrentUser) {
                this.clearMessageForm();
              }
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

    // Nettoyer les event listeners du formulaire
    if (this.messageForm) {
      // Cloner et remplacer pour supprimer tous les event listeners
      const newForm = this.messageForm.cloneNode(true);
      this.messageForm.parentNode.replaceChild(newForm, this.messageForm);
    }
  }

  // Réappliquer les styles (pour les pages restaurées depuis le cache)
  refreshStyles() {
    if (this.checkElementsReady()) {
      this.initializeMessageStyles();
      this.handleFormSubmission(); // Réinitialiser la gestion du formulaire
    }
  }
}

// Instance globale du gestionnaire de chat
const chatManager = new ChatManager();

// Utiliser uniquement les événements Turbo (Rails 7)
document.addEventListener('turbo:load', () => {
  console.log("🔄 turbo:load - initializing chat");
  chatManager.initializeChat();
});

document.addEventListener('turbo:before-cache', () => {
  console.log("🧹 turbo:before-cache - cleaning up");
  chatManager.cleanup();
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
