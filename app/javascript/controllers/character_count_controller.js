import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "count"]
  static values = { max: { type: Number, default: 2000 } }

  connect() {
    this.update()
  }

  update() {
    const current = this.inputTarget.value.length
    const max = this.maxValue
    this.countTarget.textContent = `${current} / ${max}`
    const isOver = current > max
    this.countTarget.classList.toggle("text-red-500", isOver)
    this.countTarget.classList.toggle("dark:text-red-400", isOver)
    this.countTarget.classList.toggle("text-zinc-400", !isOver)
    this.countTarget.classList.toggle("dark:text-zinc-500", !isOver)
  }
}
