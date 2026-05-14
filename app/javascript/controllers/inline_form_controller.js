import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "trigger"]

  show() {
    this.formTarget.classList.remove("hidden")
    this.triggerTarget.classList.add("hidden")
    const input = this.formTarget.querySelector("input[type=text]")
    input?.focus()
  }

  hide() {
    this.formTarget.classList.add("hidden")
    this.triggerTarget.classList.remove("hidden")
  }

  // Called via data-action="turbo:submit-end->inline-form#onSubmit" on the form element
  onSubmit(event) {
    if (event.detail.success) {
      this.hide()
      const form = this.formTarget.querySelector("form")
      form?.reset()
    }
  }
}
