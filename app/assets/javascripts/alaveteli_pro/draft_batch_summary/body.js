// Handles individual bodies in the draft bodies list
(function($, BatchAuthoritySearch, DraftBatchSummary) {
  DraftBatchSummary.Body = {};
  var SearchEvents = BatchAuthoritySearch.Events;
  var DraftEvents = DraftBatchSummary.Events;
  var $search,
      $draft;
  var formSelector = '.js-remove-authority-from-batch-form';
  var removeButtonSelector = '.js-remove_authority-from-batch-submit';

  // Lock the bodies so that people can't remove them whilst a search is
  // ongoing
  var lock = function lock() {
    $draft.find(removeButtonSelector)
          .prop('disabled', true)
          .attr('aria-disabled', true);
  };

  // Unlock the bodies so that people can remove them again
  var unlock = function unlock() {
    $draft.find(removeButtonSelector)
          .prop('disabled', false)
          .removeAttr('aria-disabled');
  };

  // Submit the "remove body from draft" form via AJAX
  var submitRemoveForm = function submitRemoveForm(e) {
    e.preventDefault();
    var $this = $(this);
    DraftBatchSummary.startNewXHR();
    DraftBatchSummary.currentXHR = $.ajax({
      url: $this.attr('action'),
      type: $this.attr('method'),
      dataType: 'html',
      data: $this.serialize()
    });
    // Trigger the usual AJAX events
    DraftBatchSummary.bindXHR();
    // Trigger an additional "Body removed" event, we pass the form and the id
    // of the body concerned as a representation of the body that was added.
    DraftBatchSummary.currentXHR.done(function() {
      $draft.trigger(
        DraftEvents.bodyRemoved,
        {$form: $this, bodyId: $this.data('body-id')});
    });
    return false;
  };

  // Bind clicks on "remove body from draft" buttons, in a function because
  // these get reloaded with new search results.
  var bindRemoveButtons = function bindRemoveButtons() {
    $(formSelector).on('submit', submitRemoveForm);
  };

  $(function(){
    $search = BatchAuthoritySearch.$el;
    $draft = DraftBatchSummary.$el;

    $search.on(SearchEvents.loading, lock);
    $search.on(SearchEvents.loadingComplete, unlock);

    $draft.on(DraftEvents.loading, lock);
    $draft.on(DraftEvents.loadingSuccess, bindRemoveButtons);
    $draft.on(DraftEvents.loadingComplete, unlock);

    bindRemoveButtons();
  });
})(window.jQuery,
   window.AlaveteliPro.BatchAuthoritySearch,
   window.AlaveteliPro.DraftBatchSummary);
