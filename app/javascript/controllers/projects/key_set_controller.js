import { Controller } from "@hotwired/stimulus";
import { streamUpdate } from "helpers/stream_update";
import Sortable from "sortablejs";

export default class extends Controller {
  static targets = ["keySet"];

  connect() {
    this.sortable = Sortable.create(this.keySetTarget, {
      handle: ".project-key-set__key__drag-handle",
      onEnd: this.updateOrder.bind(this),
    });
  }

  addKey(event) {
    event.preventDefault();
    streamUpdate(this.element, { new: true }).then(() => this.updateOrder());
  }

  removeKey(event) {
    event.preventDefault();

    const row = event.target.closest(".project-key-set__key");
    row.querySelector('input[name*="_destroy"]').value = true;

    streamUpdate(this.element);
  }

  updateKey(event) {
    streamUpdate(this.element);
  }

  updateOrder() {
    this.element
      .querySelectorAll('[name*="[order]"]')
      .forEach((element, index) => {
        element.value = index + 1;
      });
  }
}
