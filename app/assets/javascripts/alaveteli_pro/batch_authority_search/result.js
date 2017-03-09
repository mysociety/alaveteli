// Handles individual items in the search results list
(function($, BatchAuthoritySearch) {
  BatchAuthoritySearch.Result = {};
  var SearchEvents = BatchAuthoritySearch.Events;

  var $search,
      $results;
  var searchResultsButtonSelector = '.js-add-authority-to-batch-submit';

  // Lock the search results so that people can't add them whilst a search
  // is ongoing
  var lock = function lockResults() {
    $results.find(searchResultsButtonSelector)
            .prop('disabled', true)
            .attr('aria-disabled', true);
  };

  // Unlock the search results so that people can add them again
  var unlock = function unlockResults() {
    $results.find(searchResultsButtonSelector)
            .prop('disabled', false)
            .removeAttr('aria-disabled');
  };

  $(function(){
    $search = BatchAuthoritySearch.$el;
    $results = BatchAuthoritySearch.Results.$el;
    $search.on(SearchEvents.loading, lock);
    $search.on(SearchEvents.loadingComplete, unlock);
  });
})(window.jQuery, window.AlaveteliPro.BatchAuthoritySearch);
