import { Controller } from "@hotwired/stimulus"
import Mark from "mark.js"

export default class extends Controller {
  static targets = ["filter", "input", "container"]

  connect() {
    this.filterTarget.classList.remove("hide")
    this.inputTarget.value = ""

    this.marker = new Mark(this.containerTarget)
  }

  disconnect() {
    this.marker?.unmark()
  }

  filter() {
    const term = this.inputTarget.value.trim()

    this.showAll()
    this.marker.unmark()

    if (term.length <= 1) { return }

    this.marker.mark(term, { done: this.showMarksOnly.bind(this) })
  }

  categories() {
    return this.containerTarget.querySelectorAll(":scope > *")
  }

  categoriesWithoutMarks() {
    return this.containerTarget.querySelectorAll(":scope > :not(:has(mark))")
  }

  showAll() {
    this.categories().forEach(c => c.classList.remove("hide"))
  }

  showMarksOnly() {
    this.categoriesWithoutMarks().forEach(c => c.classList.add("hide"))
  }
}
