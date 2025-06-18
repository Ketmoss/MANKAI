// app/javascript/controllers/chatbot_scroll_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["end"];

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
}
