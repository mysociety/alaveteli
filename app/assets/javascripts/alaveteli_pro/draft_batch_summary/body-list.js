// Handles updating the draft batch request body list
(function($, BatchAuthoritySearch, DraftBatchSummary) {
  DraftBatchSummary.BodyList = {};
  var SearchEvents = BatchAuthoritySearch.Events;
  var DraftEvents = DraftBatchSummary.Events;

  var $search,
      $draft,
      limit,
      loadingError;
  var summarySelector = '.js-draft-batch-request-summary';
  var removeFormSelector = '.js-remove-authority-from-batch-form';

  DraftBatchSummary.bodiesIds = new Array;
  DraftBatchSummary.hasReachedLimit = false;

  // Update the displayed results
  var updateResults = function updateResults(e, data) {
    $draft.html(data.html);
  };

  // Show an error message when AJAX loading failed
  var showLoadingError = function showLoadingError(e, data) {
    // Don't show the error if we aborted the request
    if (data.textStatus !== 'abort') {
      $draft.html(
        $('<div>').addClass('ajax-error').html(loadingError)
      );
    }
  };

  var updateDraftId = function updateDraftId() {
    DraftBatchSummary.draftId = $(summarySelector, $draft).data('draft-id');

    var $draftId = $('.js-draft-id');
    var $tabs = $('.batch-builder-mode').find('.tab-title');

    if (DraftBatchSummary.draftId) {
      if ($draftId.val() === '') {
        $('.js-draft-id').val(DraftBatchSummary.draftId);
      };
    };
  };

  var cacheBodiesIds = function cacheBodiesIds() {
    DraftBatchSummary.bodiesIds = $.map(
      $(removeFormSelector, $draft), function(form) {
        return $(form).data('body-id');
      }
    );
  };

  var checkLimit = function checkLimit() {
    var hadReachedLimit = DraftBatchSummary.hasReachedLimit
    var numberOfBodies = DraftBatchSummary.bodiesIds.length

    DraftBatchSummary.hasReachedLimit = (numberOfBodies >= limit)

    stateChanged = (DraftBatchSummary.hasReachedLimit != hadReachedLimit);
    if (stateChanged && hadReachedLimit) {
      $draft.trigger(DraftEvents.hadReachedLimit);
    } else if (stateChanged) {
      $draft.trigger(DraftEvents.reachedLimit);
    }
  };

  $(function(){
    $search = BatchAuthoritySearch.$el;
    $draft = DraftBatchSummary.$el;
    limit = parseInt($draft.data('limit'));
    loadingError = $draft.data('ajax-error-message');

    $draft.on(DraftEvents.loadingSuccess, updateResults);
    $draft.on(DraftEvents.loadingSuccess, cacheBodiesIds);
    $draft.on(DraftEvents.loadingSuccess, checkLimit);
    $draft.on(DraftEvents.loadingError, showLoadingError);

    // Set the initial draftId, if there is one
    updateDraftId();

    // The draft id might change on the very first body adding, so we have to
    // get in there first to make sure we update the id we share.
    $draft.on(DraftEvents.bodyAdded, updateDraftId);
    $search.on(SearchEvents.rendered, updateDraftId);

    // Set the initial cache bodiesIds
    cacheBodiesIds();
    checkLimit();
  });
})(window.jQuery,
   window.AlaveteliPro.BatchAuthoritySearch,
   window.AlaveteliPro.DraftBatchSummary);
