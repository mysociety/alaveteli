// Handles updating the batch authority search results list
(function($, BatchAuthoritySearch) {
  BatchAuthoritySearch.Results = {};
  var SearchEvents = BatchAuthoritySearch.Events;

  var $search,
      $results,
      loadingError;

  // Update the displayed results
  var updateResults = function updateResults(e, data) {
    $results.html(data.html);
  };

  // Show an error message when AJAX loading failed
  var showLoadingError = function showLoadingError(e, data) {
    // Don't show the error if we aborted the request
    if(data.textStatus !== 'abort') {
      $results.html(
          $('<div>').addClass('ajax-error').html(loadingError)
      );
    }
  };

  $(function(){
    $search = BatchAuthoritySearch.$el;
    $results = $('.js-batch-authority-search-results');
    loadingError = $results.data('ajax-error-message');

    BatchAuthoritySearch.Results.$el = $results;

    $search.on(SearchEvents.loadingSuccess, updateResults);
    $search.on(SearchEvents.loadingError, showLoadingError);
  });
})(window.jQuery, window.AlaveteliPro.BatchAuthoritySearch);
