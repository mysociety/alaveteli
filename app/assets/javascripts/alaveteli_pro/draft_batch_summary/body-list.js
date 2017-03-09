// Handles updating the draft batch request body list
(function($, DraftBatchSummary) {
  DraftBatchSummary.BodyList = {};
  var DraftEvents = DraftBatchSummary.Events;

  var $draftSummary,
      loadingError;

  // Update the displayed results
  var updateResults = function updateResults(e, data) {
    $draftSummary.html(data.html);
  };

  // Show an error message when AJAX loading failed
  var showLoadingError = function showLoadingError(e, data) {
    // Don't show the error if we aborted the request
    if(data.textStatus !== 'abort') {
      $draftSummary.html(loadingError);
    }
  };

  $(function(){
    $draftSummary = DraftBatchSummary.$el;
    loadingError = $draftSummary.data('ajax-error-message');
    $draftSummary.on(DraftEvents.loadingSuccess, updateResults);
    $draftSummary.on(DraftEvents.loadingError, showLoadingError);
  });
})(window.jQuery, window.AlaveteliPro.DraftBatchSummary);
