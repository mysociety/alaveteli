// Handles updating the batch authority search results list
(function($, BatchAuthoritySearch) {
  BatchAuthoritySearch.Results = {};
  var SearchEvents = BatchAuthoritySearch.Events;

  var $search,
      $results,
      html,
      loadingError,
      hasLoadingError;

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

  var render = function render() {
    var content = html;

    if (hasLoadingError) {
      content = $('<div>').addClass('ajax-error').html(loadingError);
    }

    $results.html(content);
  };

  $(function(){
    $search = BatchAuthoritySearch.$el;
    $results = $('.js-batch-authority-search-results', $search);
    loadingError = $results.data('ajax-error-message');
    BatchAuthoritySearch.Results.$el = $results;

    $search.on(SearchEvents.loadingSuccess, updateResults);
    $search.on(SearchEvents.loadingError, showLoadingError);
  });
})(window.jQuery, window.AlaveteliPro.BatchAuthoritySearch);
