import { Controller } from "@hotwired/stimulus";
import Sortable from "sortablejs";

export default class extends Controller {
  static targets = ["keySet"];

  connect() {
    this.sortable = Sortable.create(this.keySetTarget, {
      handle: ".project-key-set__key__drag-handle",
      onEnd: this.updateOrder.bind(this),
    });
  }

  streamUpdate(extraData) {
    const form = this.element;
    const url = new URL(window.location.href);

    const formData = new FormData(form);
    for (const key in extraData) {
      if (extraData.hasOwnProperty(key)) {
        formData.append(key, extraData[key]);
      }
    }

    return new Promise((resolve, _reject) => {
      fetch(url.toString(), {
        method: "POST",
        headers: { Accept: "text/vnd.turbo-stream.html" },
        body: formData,
      })
        .then((response) => response.text())
        .then((html) => Turbo.renderStreamMessage(html))
        .finally(() => {
          window.requestIdleCallback
            ? window.requestIdleCallback(resolve, { timeout: 100 })
            : setTimeout(resolve, 50);
        });
    });
  }

  addKey(event) {
    event.preventDefault();
    this.streamUpdate({ new: true }).then(() => this.updateOrder());
  }

  removeKey(event) {
    event.preventDefault();

    const row = event.target.closest(".project-key-set__key");
    row.querySelector('input[name*="_destroy"]').value = true;

    this.streamUpdate();
  }

  updateOrder() {
    this.element
      .querySelectorAll('[name*="[order]"]')
      .forEach((element, index) => {
        element.value = index + 1;
      });
  }
}
