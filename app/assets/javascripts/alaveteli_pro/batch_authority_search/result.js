// Handles individual items in the search results list
(function($, BatchAuthoritySearch, DraftBatchSummary) {
  BatchAuthoritySearch.Result = {};
  var SearchEvents = BatchAuthoritySearch.Events;
  var DraftEvents = DraftBatchSummary.Events;
  var $search,
      $results,
      $draft;
  var resultSelector = '.js-batch-authority-search-results-list';
  var formSelector = '.js-add-authority-to-batch-form';
  var submitButtonSelector = '.js-add-authority-to-batch-submit';
  var bodyIdsFieldSelector = '#alaveteli_pro_draft_info_request_batch_public_body_ids';

  // Lock the search results so that people can't add them whilst a search
  // is ongoing
  var lock = function lockResults() {
    $results.find(submitButtonSelector)
            .prop('disabled', true)
            .attr('aria-disabled', true);
  };

  // Unlock the search results so that people can add them again
  var unlock = function unlockResults() {
    $results.find(submitButtonSelector)
            .prop('disabled', false)
            .removeAttr('aria-disabled');
  };

  // Submit the "add body to draft" form via AJAX
  var submitAddForm = function submitAddForm(e) {
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
    // Trigger an additional "Body added" event, we pass the form as a
    // representation of the body that was added.
    DraftBatchSummary.currentXHR.done(function() {
      $draft.trigger(DraftEvents.bodyAdded, {$form: $this});
    });
    return false;
  };

  // Bind clicks on "add body to draft" buttons, in a function because these
  // get reloaded with new search results.
  var bindAddButtons = function bindSearchResults() {
    $(formSelector).on('submit', submitAddForm);
  };

  // Remove a result from the list after a successful AJAX submission.
  // NOTE: what 'removing' actually means is TBD, for now just swaps the form
  // for a piece of text from the DOM.
  var removeResult = function removeResult(e, data) {
    var $form = data.$form;
    var $result = $form.parents(resultSelector);
    $form.replaceWith($result.data['added-text']);
  };

  // Update the hidden public_body_ids field on each search result after a
  // successful AJAX submission. So that we don't have to reload all of the
  // search results just to make future button clicks work.
  var updateForms = function updateForms(e, data) {
    var $form = data.$form;
    var addedBodyId = $form.find(bodyIdsFieldSelector).last().val();
    var $otherForms = $(formSelector).not($form);
    $otherForms.each(function() {
      var $this = $(this);
      var $newField = $this.find(bodyIdsFieldSelector).last().clone();
      $newField.val(addedBodyId);
      $this.append($newField);
    });
  };

  $(function(){
    $search = BatchAuthoritySearch.$el;
    $results = BatchAuthoritySearch.Results.$el;
    $draft = DraftBatchSummary.$el;

    $search.on(SearchEvents.loading, lock);
    $search.on(SearchEvents.loadingSuccess, bindAddButtons);
    $search.on(SearchEvents.loadingComplete, unlock);

    $draft.on(DraftEvents.loading, lock);
    $draft.on(DraftEvents.bodyAdded, removeResult);
    $draft.on(DraftEvents.bodyAdded, updateForms);
    $draft.on(DraftEvents.loadingComplete, unlock);

    bindAddButtons();
  });
})(window.jQuery, window.AlaveteliPro.BatchAuthoritySearch, window.AlaveteliPro.DraftBatchSummary);
