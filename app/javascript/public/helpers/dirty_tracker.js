/**
 * UnsavedChanges Helper
 *
 * A reusable utility class for tracking unsaved changes in forms and warning
 * users when they try to navigate away from the page with unsaved content.
 *
 * Usage:
 *
 * In a Stimulus controller:
 * ```
 * import { DirtyTracker } from "helpers/unsaved_changes";
 *
 * export default class extends Controller {
 *   connect() {
 *     this.dirty = new DirtyTracker();
 *
 *     // Optional: Auto-clear on form submission
 *     this.dirty.watchForm(this.element.closest("form"));
 *   }
 *
 *   disconnect() {
 *     this.dirty.cleanup();
 *   }
 *
 *   someAction() {
 *     // Mark as unsaved when changes are made
 *     this.dirty.markAsUnsaved();
 *   }
 * }
 * ```
 */
export class DirtyTracker {
  constructor() {
    this.hasUnsavedChanges = false;
    this.boundBeforeUnload = this.beforeUnload.bind(this);
    this.boundFormSubmit = this.onFormSubmit.bind(this);
    this.watchedForm = null;
  }

  /**
   * Handle the beforeunload event to warn users about unsaved changes
   * @param {Event} event - The beforeunload event
   * @returns {string|undefined} - Warning message or undefined
   */
  beforeUnload(event) {
    if (this.hasUnsavedChanges) {
      event.preventDefault();
      return;
    }
  }

  /**
   * Mark the form as having unsaved changes
   */
  markAsUnsaved() {
    if (!this.hasUnsavedChanges) {
      this.hasUnsavedChanges = true;
      this.addBeforeUnloadListener();
    }
  }

  /**
   * Mark the form as saved (no unsaved changes)
   */
  markAsSaved() {
    this.hasUnsavedChanges = false;
    this.removeBeforeUnloadListener();
  }

  /**
   * Watch a form for submission and automatically clear unsaved changes
   * @param {HTMLFormElement} form - The form element to watch
   */
  watchForm(form) {
    if (!form) return;

    // Remove existing listener if any
    this.unwatchForm();

    this.watchedForm = form;
    this.watchedForm.addEventListener("submit", this.boundFormSubmit);
  }

  /**
   * Stop watching the current form
   */
  unwatchForm() {
    if (this.watchedForm) {
      this.watchedForm.removeEventListener("submit", this.boundFormSubmit);
      this.watchedForm = null;
    }
  }

  /**
   * Handle form submission
   * @param {Event} event - The submit event
   */
  onFormSubmit(event) {
    this.markAsSaved();
  }

  /**
   * Add the beforeunload event listener
   */
  addBeforeUnloadListener() {
    window.addEventListener("beforeunload", this.boundBeforeUnload);
  }

  /**
   * Remove the beforeunload event listener
   */
  removeBeforeUnloadListener() {
    window.removeEventListener("beforeunload", this.boundBeforeUnload);
  }

  /**
   * Clean up all event listeners and references
   * Should be called when the controller disconnects
   */
  cleanup() {
    this.removeBeforeUnloadListener();
    this.unwatchForm();
  }
}
