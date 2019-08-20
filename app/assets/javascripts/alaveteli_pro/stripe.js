(function() {
  'use strict'

  // Setup Stripe
  var stripe = Stripe(AlaveteliPro.stripe_publishable_key);

  var form = document.getElementById('pro-signup');
  if (form) stripePaymentForm(stripe, form);
  if (AlaveteliPro.payment_intent) {
    stripePaymentIntent(stripe, AlaveteliPro.payment_intent);
  }
})();

function stripePaymentForm(stripe, form) {
  var terms = document.getElementById('pro-signup-terms');
  var submit = document.getElementById('pro-signup-submit');
  var cardError = document.getElementById('card-errors');

  // Sync initial state for terms checkbox and submit button
  terms.checked = false;
  submit.setAttribute('disabled', 'true');

  // Initialise Stripe Elements
  var elements = stripe.elements({ locale: AlaveteliPro.stripe_locale });

  // Create an instance of the card Element.
  var style = { base: { fontSize: '16px' } };
  var card = elements.create('card', { style: style });

  // Add an instance of the card Element into the `card-element` <div>.
  card.mount('#card-element');

  // Conditions which must be met before we submit the form
  var submitConditions = {
    cardError: true,
    termAccepted: false
  }

  // Listen to change events on the card Element and display any errors
  card.addEventListener('change', function(event) {
    if (event.error) {
      cardError.textContent = event.error.message;
    } else {
      cardError.textContent = '';
    }

    submitConditions.cardError = !!(event.error);
    updateSubmit();
  });

  // Enable submit button if terms are accepted
  terms.addEventListener('click', function(event) {
    if (this.checked) {
      submitConditions.termAccepted = true;
    }	else {
      submitConditions.termAccepted = false;
    }
    updateSubmit();
  });

  // Create a token or display an error when the form is submitted
  form.addEventListener('submit', function(event) {
    event.preventDefault();

    // Ensure submit conditions are met
    if (!canSubmit()) { return false; }

    stripe.createToken(card).then(function(result) {
      if (result.error) {
        // Inform the customer that there was an error
        cardError.textContent = result.error.message;

        // Prevent re-submitting after error
        submitConditions.cardError = true;
        updateSubmit();

        // Reset submit button value which was changed by Rails' UJS
        // disable-with option
        var text = $(submit).data('ujs:enable-with');
        if (text) $(submit)['val'](text);
      } else {
        // Send the token to your server.
        stripeTokenHandler(result.token);
      }
    });
  });

  function canSubmit() {
    return !submitConditions.cardError && submitConditions.termAccepted;
  }

  function updateSubmit() {
    if (canSubmit()) {
      submit.removeAttribute('disabled');
    } else {
      submit.setAttribute('disabled', 'true');
    }
  }

  function stripeTokenHandler(token) {
    // Insert the token ID into the form so it gets submitted to the server
    var hiddenInput = document.createElement('input');
    hiddenInput.setAttribute('type', 'hidden');
    hiddenInput.setAttribute('name', 'stripe_token');
    hiddenInput.setAttribute('value', token.id);
    form.appendChild(hiddenInput);

    // Submit the form
    form.submit();
  }
}

function stripePaymentIntent(stripe, paymentIntent) {
  stripe.handleCardPayment(
    paymentIntent
  ).then(function(result) {
    location.reload();
  });
}
