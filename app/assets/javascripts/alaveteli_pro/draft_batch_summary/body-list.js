// Handles updating the draft batch request body list
(function($, DraftBatchSummary) {
  DraftBatchSummary.BodyList = {};
  var DraftEvents = DraftBatchSummary.Events;

  var $draft,
      limit,
      loadingError;
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
    $draft = DraftBatchSummary.$el;
    limit = parseInt($draft.data('limit'));
    loadingError = $draft.data('ajax-error-message');

    $draft.on(DraftEvents.loadingSuccess, updateResults);
    $draft.on(DraftEvents.loadingSuccess, cacheBodiesIds);
    $draft.on(DraftEvents.loadingSuccess, checkLimit);
    $draft.on(DraftEvents.loadingError, showLoadingError);

    // Set the initial cache bodiesIds
    cacheBodiesIds();
    checkLimit();
  });
})(window.jQuery, window.AlaveteliPro.DraftBatchSummary);
