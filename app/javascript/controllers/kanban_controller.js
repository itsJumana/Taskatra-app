import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  static targets = ["column"]

  connect() {
    this.#sortables = this.columnTargets.map((column) =>
      Sortable.create(column, {
        group: "tasks",
        animation: 150,
        ghostClass: "opacity-40",
        dragClass: "shadow-xl",
        handle: "[data-drag-handle]",
        onEnd: (event) => this.#onDrop(event)
      })
    )
  }

  disconnect() {
    this.#sortables?.forEach((s) => s.destroy())
    this.#sortables = null
  }

  // Private

  #sortables = null

  #onDrop(event) {
    const taskId = event.item.dataset.taskId
    const newStatus = event.to.dataset.columnStatus
    const newPosition = event.newIndex

    if (!taskId || !newStatus) return

    const csrfToken = document.querySelector("[name=csrf-token]")?.content
    if (!csrfToken) return

    fetch(`/tasks/${taskId}/status`, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken
      },
      body: JSON.stringify({ status: newStatus, position: newPosition })
    }).then((response) => {
      if (!response.ok) {
        // Revert the DOM move on failure — SortableJS does not auto-revert
        const originalColumn = event.from
        const item = event.item
        const oldIndex = event.oldIndex
        if (oldIndex < originalColumn.children.length) {
          originalColumn.insertBefore(item, originalColumn.children[oldIndex])
        } else {
          originalColumn.appendChild(item)
        }
      }
    })
  }
}
