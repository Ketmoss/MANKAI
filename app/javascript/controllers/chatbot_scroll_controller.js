// app/javascript/controllers/chatbot_scroll_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["end", "loader", "form"];

  connect() {
    this.scrollToBottom();
    this.observer = new MutationObserver(() => this.scrollToBottom());
    this.observer.observe(this.element, { childList: true, subtree: true });
  }

  disconnect() {
    this.observer.disconnect();
  }

  scrollToBottom() {
    this.endTarget.scrollIntoView({ behavior: "smooth" });
  }

  revealLoader(event) {
    event.preventDefault();
    this.loaderTarget.style.display = "block";
    this.formTarget.submit();
  }
}
