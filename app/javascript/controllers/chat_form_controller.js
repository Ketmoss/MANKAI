import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["textarea", "submit"]

  connect() {
    this.autoResize()
  }

  handleKeydown(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      this.submitForm()
    }
  }

  autoResize() {
    const textarea = this.textareaTarget
    textarea.style.height = "auto"
    textarea.style.height = Math.min(textarea.scrollHeight, 120) + "px"
  }

  submitForm() {
    const content = this.textareaTarget.value.trim()
    if (content) {
      this.submitTarget.click()
    }
  }
}
