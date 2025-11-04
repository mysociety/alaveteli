import { Controller } from "@hotwired/stimulus";
import { streamUpdate } from "helpers/stream_update";

export default class extends Controller {
  static targets = ["newInput"];
  static values = { name: String };

  addOption(event) {
    event.preventDefault();

    const newValue = this.newInputTarget.value;
    if (!newValue) return;

    const form = this.element.closest("form");
    streamUpdate(form, { [this.nameValue]: newValue });
  }

  removeOption(event) {
    event.preventDefault();

    const li = event.target.closest("li");
    if (li) li.remove();
  }
}
