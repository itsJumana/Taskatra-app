import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "label", "input"]

  connect() {
    this.#handleOutsideClick = this.#onOutsideClick.bind(this)
  }

  disconnect() {
    document.removeEventListener("click", this.#handleOutsideClick, { capture: true })
  }

  toggle() {
    const isOpen = !this.menuTarget.classList.contains("hidden")
    if (isOpen) {
      this.#closeMenu()
    } else {
      this.#openMenu()
    }
  }

  select(event) {
    const value = event.currentTarget.dataset.value
    const label = event.currentTarget.dataset.label || event.currentTarget.textContent.trim()
    this.inputTarget.value = value
    this.labelTarget.textContent = label
    this.#closeMenu()
  }

  // Private

  #handleOutsideClick = null

  #openMenu() {
    this.menuTarget.classList.remove("hidden")
    document.addEventListener("click", this.#handleOutsideClick, { capture: true })
  }

  #closeMenu() {
    this.menuTarget.classList.add("hidden")
    document.removeEventListener("click", this.#handleOutsideClick, { capture: true })
  }

  #onOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.#closeMenu()
    }
  }
}
