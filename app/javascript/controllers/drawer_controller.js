import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  open(event) {
    const url = event.currentTarget.dataset.url
    if (!url) return

    const frame = document.getElementById("task-drawer")
    const backdrop = document.getElementById("task-drawer-backdrop")

    if (!frame || !backdrop) return

    // Setting src triggers Turbo Frame fetch — Turbo finds <turbo-frame id="task-drawer"> in response and swaps content
    frame.src = url

    frame.classList.remove("translate-x-full")
    frame.classList.add("translate-x-0")

    backdrop.classList.remove("hidden")
  }

  close() {
    const frame = document.getElementById("task-drawer")
    const backdrop = document.getElementById("task-drawer-backdrop")

    if (!frame || !backdrop) return

    frame.classList.remove("translate-x-0")
    frame.classList.add("translate-x-full")

    backdrop.classList.add("hidden")
  }
}
