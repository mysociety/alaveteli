// Handles pagination of the search results list
(function($, BatchAuthoritySearch){
  BatchAuthoritySearch.Pagination = {};
  var SearchEvents = BatchAuthoritySearch.Events;

  var $search;
  var paginationSelector = '.js-batch-authority-search-results .pagination a';

  // Load a new page of search results via AJAX
  var loadNewPage = function loadNewPage(e, path, data) {
    e.preventDefault();
    BatchAuthoritySearch.startNewXHR();
    BatchAuthoritySearch.currentXHR = $.ajax({
      url: path,
      type: 'get',
      dataType: 'html',
      data: data
    });
    BatchAuthoritySearch.bindXHR();
    return false;
  };

  // Lock the pagination links so that people can't use them whilst a search
  // is going on.
  var lock = function lock() {
    $(paginationSelector).addClass('disabled')
                         .attr('aria-disabled', true);
  };

  // Unlock the pagination links so that people can use them again
  var unlock = function unlock() {
    $(paginationSelector).removeClass('disabled')
                         .removeAttr('aria-disabled');
  };

  // Bind click events on the pagination links, which get reloaded with new
  // search results, hence this being in a function.
  var bindClicks = function bindClicks() {
    $(paginationSelector).on('click', function(e) {
      var $this = $(this);
      e.preventDefault();
      // Clicks on disabled links just get ignored
      if (!$this.hasClass('disabled')) {
        // Parse the data we'll submit with the form from the link url
        var urlParts = $this.attr('href').split('?');
        var path = urlParts[0];
        var querystring = urlParts[1];
        var params = $.deparam(querystring);
        loadNewPage(e, path, params);
      }
      return false;
    });
  };

  $(function(){
    $search = BatchAuthoritySearch.$el;

    $search.on(SearchEvents.loading, lock);
    $search.on(SearchEvents.loadingSuccess, bindClicks);
    $search.on(SearchEvents.loadingComplete, unlock);

    bindClicks();
  });
})(window.jQuery, window.AlaveteliPro.BatchAuthoritySearch);
