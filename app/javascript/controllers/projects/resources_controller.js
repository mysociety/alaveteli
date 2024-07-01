import { Controller } from "@hotwired/stimulus";

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

        this.streamUpdate({ page: page });
      }
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

  search() {
    const query = this.queryTarget.value;

    this.streamUpdate({ query: query, page: 1 });
  }

  add(name, id) {
    this.streamUpdate({ [`project[${name}_ids][]`]: id });
  }

  remove(name, id) {
    this.element
      .querySelectorAll(`input[name="project[${name}_ids][]"][value="${id}"]`)
      .forEach((input) => input.remove());

    this.streamUpdate();
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
