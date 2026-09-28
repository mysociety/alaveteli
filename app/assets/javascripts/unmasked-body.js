// Toggles between the masked and unmasked main body text of an incoming
// message. The unmasked text is loaded on demand as it has to be pulled from
// the raw email.
(function() {
  var loadingClass = 'toggle-unmasked-body--loading';
  var maskedHTML = new WeakMap();

  function showMasked(toggle, body) {
    body.innerHTML = maskedHTML.get(toggle);
    maskedHTML.delete(toggle);
    toggle.textContent = toggle.dataset.showText;
  }

  function showUnmasked(toggle, body) {
    var error = toggle.closest('.correspondence').
      querySelector('.js-unmasked-body-ajax-error');

    toggle.classList.add(loadingClass);
    if (error) error.hidden = true;

    fetch(toggle.href, {
      headers: { 'X-Requested-With': 'XMLHttpRequest' },
      credentials: 'same-origin',
      cache: 'no-store'
    }).then(function(response) {
      if (!response.ok) throw new Error(response.statusText);
      return response.text();
    }).then(function(html) {
      maskedHTML.set(toggle, body.innerHTML);
      toggle.dataset.showText = toggle.textContent;
      toggle.textContent = toggle.dataset.hideText;
      body.innerHTML = html;
    }).catch(function() {
      if (error) error.hidden = false;
    }).finally(function() {
      toggle.classList.remove(loadingClass);
    });
  }

  document.addEventListener('click', function(e) {
    var toggle = e.target.closest('.js-toggle-unmasked-body');
    if (!toggle) return;

    e.preventDefault();
    if (toggle.classList.contains(loadingClass)) return;

    var body = document.getElementById(toggle.dataset.body);
    if (!body) return;

    if (maskedHTML.has(toggle)) {
      showMasked(toggle, body);
    } else {
      showUnmasked(toggle, body);
    }
  });
})();
