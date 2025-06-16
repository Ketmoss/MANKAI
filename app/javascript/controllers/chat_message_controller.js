import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    userId: Number,
    currentUserId: Number
  }

  connect() {
    console.log("Chat message controller connected")
    this.applyStyles()
  }

  applyStyles() {
    const isOwn = this.userIdValue === this.currentUserIdValue

    if (isOwn) {
      this.element.style.backgroundColor = '#DCF8C6'
      this.element.style.marginLeft = 'auto'
      this.element.style.marginRight = '0'
    } else {
      this.element.style.backgroundColor = '#F1F0F0'
      this.element.style.marginLeft = '0'
      this.element.style.marginRight = 'auto'
    }
  }
}
