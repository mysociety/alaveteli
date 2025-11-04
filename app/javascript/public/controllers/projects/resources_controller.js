import { Controller } from "@hotwired/stimulus";
import { streamUpdate } from "helpers/stream_update";
import { DirtyTracker } from "helpers/dirty_tracker";

export default class extends Controller {
  static targets = ["query"];

  connect() {
    this.dirty = new DirtyTracker();

    // Auto-watch form for submission
    const form = this.element.closest("form");
    if (form) {
      this.dirty.watchForm(form);
    }

    if (this.queryTarget.value) {
      this.search();
    }

    this.element.addEventListener("click", (event) => {
      if (event.target.matches(".pagination a")) {
        event.preventDefault();

        const url = new URL(event.target.href);
        const page = url.searchParams.get("page");
        this.element.querySelector("input[name=page]").value = page;

        streamUpdate(this.element, { page: page });
      }
    });
  }

  disconnect() {
    this.dirty.cleanup();
  }

  search() {
    const query = this.queryTarget.value;

    streamUpdate(this.element, { query: query, page: 1 });
  }

  add(name, id) {
    this.dirty.markAsUnsaved();
    streamUpdate(this.element, { [`project[${name}_ids][]`]: id });
  }

  remove(name, id) {
    this.dirty.markAsUnsaved();
    this.element
      .querySelectorAll(`input[name="project[${name}_ids][]"][value="${id}"]`)
      .forEach((input) => input.remove());

    streamUpdate(this.element);
  }

  addBatch(event) {
    event.preventDefault();
    this.add("batch", event.params.id);
  }

  addRequest(event) {
    event.preventDefault();
    this.add("request", event.params.id);
  }

  removeBatch(event) {
    event.preventDefault();
    this.remove("batch", event.params.id);
  }

  removeRequest(event) {
    event.preventDefault();
    this.remove("request", event.params.id);
  }
}
