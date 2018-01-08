// Handles updating the draft batch request body list
(function($, DraftBatchSummary) {
  DraftBatchSummary.BodyList = {};
  var DraftEvents = DraftBatchSummary.Events;

  var $draft,
      loadingError;

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

  $(function(){
    $draft = DraftBatchSummary.$el;
    loadingError = $draft.data('ajax-error-message');

    $draft.on(DraftEvents.loadingSuccess, updateResults);
    $draft.on(DraftEvents.loadingError, showLoadingError);
  });
})(window.jQuery, window.AlaveteliPro.DraftBatchSummary);
