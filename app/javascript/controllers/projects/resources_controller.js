import { Controller } from "@hotwired/stimulus";
import { streamUpdate } from "helpers/stream_update";

export default class extends Controller {
  static targets = ["query"];

  connect() {
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

  search() {
    const query = this.queryTarget.value;

    streamUpdate(this.element, { query: query, page: 1 });
  }

  add(name, id) {
    streamUpdate(this.element, { [`project[${name}_ids][]`]: id });
  }

  remove(name, id) {
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
