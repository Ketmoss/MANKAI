import consumer from "./consumer"

let subscription;

document.addEventListener("turbo:load", () => {
  const chatElement = document.getElementById("chat-messages");
  if (!chatElement) return;

  const chatId = chatElement.dataset.chatId;

  if (subscription) {
    consumer.subscriptions.remove(subscription);
  }

  subscription = consumer.subscriptions.create(
    { channel: "ChatChannel", chat_id: chatId },
    {
      received(data) {
        chatElement.insertAdjacentHTML("beforeend", data.message);
        chatElement.scrollTop = chatElement.scrollHeight; // scroll vers le bas
      }
    }
  );
});
