import { Controller } from "@hotwired/stimulus";
import { streamUpdate } from "helpers/stream_update";

export default class extends Controller {
  connect() {}

  remove(event) {
    event.preventDefault();

    this.element
      .querySelectorAll(
        `input[name="project[contributor_ids][]"][value="${event.params.id}"]`,
      )
      .forEach((input) => input.remove());

    streamUpdate(this.element);
  }
}
