// Handles updating the batch authority search results list
(function($, BatchAuthoritySearch, DraftBatchSummary) {
  BatchAuthoritySearch.Results = {};
  var SearchEvents = BatchAuthoritySearch.Events;
  var DraftEvents = DraftBatchSummary.Events;

  var $search,
      $draft,
      $results,
      html,
      loadingError,
      hasLoadingError,
      limitReached;

  // DOM might be updated from another compentent if so this method can be
  // called to ensure the correct message is rendered
  var update = function update() {
    if (!DraftBatchSummary.hasReachedLimit && !hasLoadingError) {
      html = $results.html();
    }
    updateResults();
  };

  // Update the displayed results
  var updateResults = function updateResults(e, data) {
    hasLoadingError = false;
    if (data) {
      html = data.html;
    }
    render();
  };

  // Show an error message when AJAX loading failed
  var showLoadingError = function showLoadingError(e, data) {
    // Don't show the error if we aborted the request
    if (data.textStatus !== 'abort') {
      hasLoadingError = true;
      render();
    }
  };

  // Main render method
  var render = function render() {
    var content = html;

    if (DraftBatchSummary.hasReachedLimit) {
      content = $('<div>').addClass('blank-slate').html(limitReached);
    } else if (hasLoadingError) {
      content = $('<div>').addClass('ajax-error').html(loadingError);
    }

    $results.html(content);
    $search.trigger(SearchEvents.rendered);
  };

  $(function(){
    $search = BatchAuthoritySearch.$el;
    $draft = DraftBatchSummary.$el;
    $results = $('.js-batch-authority-search-results', $search);
    html = $results.html();
    loadingError = $results.data('ajax-error-message');
    limitReached = $results.data('limit-reached-message');
    BatchAuthoritySearch.Results.$el = $results;

    $search.on(SearchEvents.domUpdated, update);
    $search.on(SearchEvents.loadingSuccess, updateResults);
    $search.on(SearchEvents.loadingError, showLoadingError);

    $draft.on(DraftEvents.reachedLimit, render);
    $draft.on(DraftEvents.hadReachedLimit, render);
  });
})(window.jQuery,
   window.AlaveteliPro.BatchAuthoritySearch,
   window.AlaveteliPro.DraftBatchSummary);
