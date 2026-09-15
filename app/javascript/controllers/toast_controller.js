import { Controller } from "@hotwired/stimulus"

// Dismisses a flash message on its own, fading it out first.
export default class extends Controller {
  static values = {
    delay: { type: Number, default: 5000 },
    fade: { type: Number, default: 300 }
  }

  connect() {
    this.timeout = setTimeout(() => this.dismiss(), this.delayValue)
  }

  disconnect() {
    clearTimeout(this.timeout)
    clearTimeout(this.fadeTimeout)
  }

  dismiss() {
    this.element.classList.add("transition-opacity", "duration-300", "opacity-0")
    this.fadeTimeout = setTimeout(() => this.element.remove(), this.fadeValue)
  }
}
