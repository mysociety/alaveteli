export function streamUpdate(form, extraData) {
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
