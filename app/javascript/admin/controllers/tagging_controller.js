import { Controller } from "@hotwired/stimulus"

const tagLists = {}

function fetchTagList(url) {
  tagLists[url] ||= fetch(url).
    then(response => response.ok ? response.json() : []).
    catch(() => [])

  return tagLists[url]
}

export default class extends Controller {
  static targets = ["field", "tags", "input", "list", "template"]
  static values = {
    url: { type: String, default: "/admin/tags/list_for_widget.json" }
  }

  connect() {
    this.knownTags = []
    this.fieldTarget.style.display = "none"
    this.fieldTarget.value.split(" ").forEach(name => this.addTag(name))

    fetchTagList(this.urlValue).then(tags => {
      this.knownTags = tags.map(tag => tag.t)
      this.updateDatalist()
    })
  }

  disconnect() {
    this.fieldTarget.style.removeProperty("display")
  }

  focus() {
    this.inputTarget.focus()
  }

  changed() {
    this.validate()
  }

  validate() {
    const pending = this.inputTarget.value.trim()

    this.inputTarget.setCustomValidity(
      pending === "" ?
        "" :
        `Add "${pending}" as a tag with the space bar, or clear the box`
    )
  }

  keydown(event) {
    if (event.key === "Backspace" && this.inputTarget.value === "") {
      this.dropTag(this.tagsTarget.lastElementChild)
    } else if (event.key === "Tab" && this.inputTarget.value.trim() !== "") {
      event.preventDefault()
      this.autoComplete()
    } else if (event.key === " ") {
      event.preventDefault()
      this.commit()
    }
  }

  keyup(event) {
    if (event.key === "Enter") this.commit()
  }

  autoComplete() {
    if (this.completedValue) {
      this.inputTarget.value = this.completedValue
    } else {
      this.commit()
    }
  }

  commit() {
    this.addTag(this.inputTarget.value.trim())
    this.inputTarget.value = ""
    this.validate()
    this.updateDatalist()
    this.closePicker()
  }

  addTag(name) {
    if (name === "" || this.tags.includes(name)) return

    const tag = this.templateTarget.content.firstElementChild.cloneNode(true)
    tag.prepend(name)

    this.tagsTarget.append(tag)
    this.updateInput()
  }

  removeTag(event) {
    this.dropTag(event.target.closest("code"))
    this.focus()
  }

  dropTag(tag) {
    if (!tag) return

    tag.remove()
    this.updateInput()
    this.updateDatalist()
  }

  updateInput() {
    this.fieldTarget.value = this.tags.join(" ")
  }

  updateDatalist() {
    this.listTarget.replaceChildren(...this.unusedTags.map(name => {
      const option = document.createElement("option")
      option.value = name
      return option
    }))
  }

  closePicker() {
    this.inputTarget.removeAttribute("list")

    requestAnimationFrame(() => {
      this.inputTarget.setAttribute("list", this.listTarget.id)
    })
  }

  get completedValue() {
    const typed = this.inputTarget.value.trim().toLowerCase()
    if (typed === "") return null

    const matches = this.unusedTags.
      filter(name => name.toLowerCase().startsWith(typed))

    if (matches.length !== 1 || matches[0].toLowerCase() === typed) return null

    return matches[0]
  }

  get unusedTags() {
    return this.knownTags.filter(name => !this.tags.includes(name))
  }

  get tags() {
    return Array.from(this.tagsTarget.children, tag => tag.firstChild.data)
  }
}
