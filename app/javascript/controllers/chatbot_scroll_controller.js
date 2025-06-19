// app/javascript/controllers/chatbot_scroll_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["loader", "content", "form", "end"];

  connect() {
    // cache le loader au démarrage
    this.loaderTarget.classList.add("d-none");
    // scroll smooth en bas au chargement
    this.scrollToEnd();
  }

  revealLoader(event) {
    // empêche le double-submit
    this.formTarget
      .querySelector("input[type=submit], button[type=submit]")
      .setAttribute("disabled", "true");

    // masque le contenu et affiche le loader
    this.contentTarget.classList.add("d-none");
    this.loaderTarget.classList.remove("d-none");
  }

  showContent() {
    // si tu reviens via JS/AJAX : repasse en affichage et scroll
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        this.scrollToEnd();
      });
    });
  }

  scrollToEnd() {
    if (this.hasEndTarget) {
      this.endTarget.scrollIntoView({ behavior: "smooth" });
    }
  }
}
