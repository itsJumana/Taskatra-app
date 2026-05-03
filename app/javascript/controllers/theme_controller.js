import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { default: { type: String, default: "system" } }

  connect() {
    this.applyTheme(this.#savedTheme)
    this.#watchSystemTheme()
  }

  disconnect() {
    this.#mediaQuery?.removeEventListener("change", this.#onSystemChange)
  }

  toggle() {
    const isDark = document.documentElement.classList.contains("dark")
    const next = isDark ? "light" : "dark"
    localStorage.setItem("taskflow-theme", next)
    this.applyTheme(next)
  }

  applyTheme(theme) {
    const prefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches
    const shouldBeDark = theme === "dark" || (theme === "system" && prefersDark)
    document.documentElement.classList.toggle("dark", shouldBeDark)
  }

  get #savedTheme() {
    return localStorage.getItem("taskflow-theme") || this.defaultValue
  }

  #mediaQuery = window.matchMedia("(prefers-color-scheme: dark)")

  #onSystemChange = () => {
    if (this.#savedTheme === "system") this.applyTheme("system")
  }

  #watchSystemTheme() {
    this.#mediaQuery.addEventListener("change", this.#onSystemChange)
  }
}
