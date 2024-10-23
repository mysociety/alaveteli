import { Controller } from "@hotwired/stimulus";
import { createSubscription } from '../channels/raw_email_channel'

export default class extends Controller {
  static targets = ['eraseButton', 'status'];
  static values = { id: Number };

  connect() {
    this.setupChannelSubscription();
  }

  setupChannelSubscription() {
    createSubscription({
      rawEmailID: this.idValue,
      cb: (response) => this.handleChannelEvent(response.data)
    });
  }

  erase(event) {
    event.preventDefault();

    this.eraseButtonTarget.disabled = true;
    this.eraseButtonTarget.textContent = 'Erasing...';
    this.statusTarget.innerHTML = 'Processing...';

    this.eraseButtonTarget.closest('form').requestSubmit();
  }

  handleChannelEvent(data) {
    if (data.event === 'erased') {
      this.statusTarget.innerHTML = 'Done!';
      this.eraseButtonTarget.disabled = false;
      this.eraseButtonTarget.textContent = 'Erase';
    }
  }
}
