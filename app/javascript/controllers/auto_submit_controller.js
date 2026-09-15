import { Controller } from "@hotwired/stimulus"

// The submitted element lives inside the turbo-frame it reloads, so the response
// replaces it with a brand new node and typing loses focus. This remembers which
// element to hand the focus back to — by id, since the users list renders one
// controller per row and only the element being used should get it back.
let refocusId = null

// Submits the form the element belongs to. With a delay, waits for typing to
// stop first (search field); without one, submits immediately (role toggle).
export default class extends Controller {
  static values = { delay: { type: Number, default: 0 } }

  connect() {
    // The role toggles carry no id, so an empty one must never match.
    if (!refocusId || refocusId !== this.element.id) return

    refocusId = null
    this.element.focus()

    // A freshly parsed input starts with the caret at 0, so typing would land in
    // front of what is already there.
    const end = this.element.value.length
    this.element.setSelectionRange(end, end)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  submit() {
    clearTimeout(this.timeout)

    if (this.delayValue === 0) return this.submitNow()

    this.timeout = setTimeout(() => this.submitNow(), this.delayValue)
  }

  submitNow() {
    refocusId = document.activeElement === this.element ? this.element.id : null
    this.element.form.requestSubmit()
  }
}
