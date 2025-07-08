import { Controller } from "@hotwired/stimulus";
import { streamUpdate } from "helpers/stream_update";
import { DirtyTracker } from "helpers/dirty_tracker";

export default class extends Controller {
  connect() {
    this.dirty = new DirtyTracker();

    // Auto-watch form for submission
    const form = this.element.closest("form");
    if (form) {
      this.dirty.watchForm(form);
    }
  }

  disconnect() {
    this.dirty.cleanup();
  }

  remove(event) {
    this.dirty.markAsUnsaved();
    event.preventDefault();

    this.element
      .querySelectorAll(
        `input[name="project[contributor_ids][]"][value="${event.params.id}"]`,
      )
      .forEach((input) => input.remove());

    streamUpdate(this.element);
  }
}
