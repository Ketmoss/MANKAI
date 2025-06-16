import consumer from "./consumer"

document.addEventListener('DOMContentLoaded', () => {
  const chatElement = document.getElementById('chat-messages');
  const chatId = chatElement.dataset.chatId;

  consumer.subscriptions.create({ channel: "ChatChannel", chat_id: chatId }, {
    received(data) {
      chatElement.insertAdjacentHTML('beforeend', data.message);
    }
  });
});
