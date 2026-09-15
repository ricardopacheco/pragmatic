import { Controller } from "@hotwired/stimulus"

// Opens a <dialog>. When the trigger carries url/name params, they fill in the
// form action and the name shown in the confirmation, so one dialog serves a
// whole list.
export default class extends Controller {
  static targets = ["dialog", "form", "name"]

  connect() {
    // Morphing strips the open attribute without calling close(), and only close()
    // releases the top layer: the page would stay blocked by a modal nobody can see.
    // This covers both renders that reach an open dialog — our own submit, and a
    // broadcast refresh caused by someone else.
    this.closeOnRender = () => this.close()
    document.addEventListener("turbo:before-render", this.closeOnRender)
  }

  disconnect() {
    document.removeEventListener("turbo:before-render", this.closeOnRender)
  }

  open({ params: { url, name } }) {
    if (url && this.hasFormTarget) this.formTarget.action = url
    if (name && this.hasNameTarget) this.nameTarget.textContent = name

    this.dialogTarget.showModal()
  }

  close() {
    if (this.hasDialogTarget && this.dialogTarget.open) this.dialogTarget.close()
  }
}
