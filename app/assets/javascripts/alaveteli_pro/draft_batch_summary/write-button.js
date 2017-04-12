// Handles updating the draft batch request body list
(function($, DraftBatchSummary) {
  DraftBatchSummary.BodyList = {};
  var DraftEvents = DraftBatchSummary.Events;

  var $draftSummary,
      $writeButton,
      $draftId;

  var authorityInListSelector = '.batch-builder__authority-list__authority';

  // Enable the 'write request' button, if there are any selected authorities
  var enableButton = function enableButton() {
    if($draftSummary.find(authorityInListSelector).length > 0) {
      $writeButton.prop('disabled', false);
    }
  };

  // Disable the 'write request' button, if there are no selected authorities
  var disableButton = function disableButton() {
    if($draftSummary.find(authorityInListSelector).length === 0) {
      $writeButton.prop('disabled', true);
    }
  };

  // Update the hidden draft_id column in case it doesn't have a value yet
  var updateDraftId = function updateDraftId() {
    if($draftId.val() === '') {
      $draftId.val(DraftBatchSummary.draftId);
    }
  };

  $(function(){
    $draftSummary = DraftBatchSummary.$el;
    $writeButton = $('.js-write-request-button');
    $draftId = $('.js-write-button-draft-id');

    $draftSummary.on(DraftEvents.bodyAdded, updateDraftId);
    $draftSummary.on(DraftEvents.bodyAdded, enableButton);
    $draftSummary.on(DraftEvents.bodyRemoved, disableButton);
  });
})(window.jQuery, window.AlaveteliPro.DraftBatchSummary);
