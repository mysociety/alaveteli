import { Controller } from "@hotwired/stimulus";
import { streamUpdate } from "helpers/stream_update";
import { DirtyTracker } from "helpers/dirty_tracker";
import Sortable from "sortablejs";

export default class extends Controller {
  static targets = ["keySet"];

  connect() {
    this.dirty = new DirtyTracker();

    // Auto-watch form for submission
    const form = this.element.closest("form");
    if (form) {
      this.dirty.watchForm(form);
    }

    this.sortable = Sortable.create(this.keySetTarget, {
      handle: ".project-key-set__key__drag-handle",
      onEnd: this.updateOrder.bind(this),
    });
  }

  disconnect() {
    this.dirty.cleanup();
  }

  addKey(event) {
    this.dirty.markAsUnsaved();
    event.preventDefault();
    streamUpdate(this.element, { new: true }).then(() => this.updateOrder());
  }

  removeKey(event) {
    this.dirty.markAsUnsaved();
    event.preventDefault();

    const row = event.target.closest(".project-key-set__key");
    row.querySelector('input[name*="_destroy"]').value = true;

    streamUpdate(this.element);
  }

  updateKey(event) {
    this.dirty.markAsUnsaved();
    streamUpdate(this.element);
  }

  updateOrder() {
    this.dirty.markAsUnsaved();
    this.element
      .querySelectorAll('[name*="[order]"]')
      .forEach((element, index) => {
        element.value = index + 1;
      });
  }
}
