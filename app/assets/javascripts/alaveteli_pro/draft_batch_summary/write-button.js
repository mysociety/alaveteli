// Handles updating the draft batch request body list
(function($, DraftBatchSummary) {
  DraftBatchSummary.BodyList = {};
  var DraftEvents = DraftBatchSummary.Events;

  var $draft,
      $writeButton,
      $draftId;

  var authorityInListSelector = '.batch-builder__list__item';

  // Enable the 'write request' button, if there are any selected authorities
  var enableButton = function enableButton() {
    if ($draft.find(authorityInListSelector).length > 0) {
      $writeButton.prop('disabled', false);
    }
  };

  // Disable the 'write request' button, if there are no selected authorities
  var disableButton = function disableButton() {
    if ($draft.find(authorityInListSelector).length === 0) {
      $writeButton.prop('disabled', true);
    }
  };

  // Update the hidden draft_id column in case it doesn't have a value yet
  var updateDraftId = function updateDraftId() {
    if ($draftId.val() === '') {
      $draftId.val(DraftBatchSummary.draftId);
    }
  };

  $(function(){
    $draft = DraftBatchSummary.$el;
    $writeButton = $('.js-write-request-button');
    $draftId = $('.js-write-button-draft-id');

    $draft.on(DraftEvents.bodyAdded, updateDraftId);
    $draft.on(DraftEvents.bodyAdded, enableButton);
    $draft.on(DraftEvents.bodyRemoved, disableButton);
  });
})(window.jQuery, window.AlaveteliPro.DraftBatchSummary);
