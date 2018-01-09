// Handles updating the draft batch request body list
(function($, DraftBatchSummary) {
  DraftBatchSummary.BodyList = {};
  var DraftEvents = DraftBatchSummary.Events;

  var $draft,
      loadingError;
  var removeFormSelector = '.js-remove-authority-from-batch-form';

  DraftBatchSummary.bodiesIds = new Array;

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

  $(function(){
    $draft = DraftBatchSummary.$el;
    loadingError = $draft.data('ajax-error-message');

    $draft.on(DraftEvents.loadingSuccess, updateResults);
    $draft.on(DraftEvents.loadingSuccess, cacheBodiesIds);
    $draft.on(DraftEvents.loadingError, showLoadingError);

    // Set the initial cache bodiesIds
    cacheBodiesIds();
  });
})(window.jQuery, window.AlaveteliPro.DraftBatchSummary);
