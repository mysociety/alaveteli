// Top level object to hold all of the Batch Authority Search things and
// handle things which happen at the very top level
// (the search/browse results; pane on the left)
(function($, AlaveteliPro){
  var BatchAuthoritySearch = AlaveteliPro.BatchAuthoritySearch = {};
  var $el;
  var namespace = AlaveteliPro.Events.namespace + ':BatchAuthoritySearch';
  var Events = BatchAuthoritySearch.Events = {
    namespace: namespace,
    loading: namespace + ':loading',
    loadingSuccess: namespace + ':loadingSuccess',
    loadingError: namespace + ':loadingError',
    loadingComplete: namespace + ':loadingComplete',
    domUpdated: namespace + ':domUpdated',
    rendered: namespace + ':rendered'
  };

  BatchAuthoritySearch.currentXHR = null;

  // Start a new XHR request, aborts any existing one and triggers a loading
  // event on the root element to tell everything about it.
  BatchAuthoritySearch.startNewXHR = function startNewXHR() {
    if (BatchAuthoritySearch.currentXHR) {
      BatchAuthoritySearch.currentXHR.abort();
    }
    $el.trigger(Events.loading);
  };

  // Bind to the various outcomes of the currentXHR so that we trigger the
  // right events when things happen with it
  BatchAuthoritySearch.bindXHR = function bindXHR() {
    BatchAuthoritySearch.currentXHR.done(function(data) {
      $el.trigger(Events.loadingSuccess, {html: data});
    });
    BatchAuthoritySearch.currentXHR.fail(function(xhr, textStatus) {
      $el.trigger(Events.loadingError, {textStatus: textStatus});
    });
    BatchAuthoritySearch.currentXHR.always(function() {
      $el.trigger(Events.loadingComplete);
    });
  };

  var addLoadingClass = function addLoadingClass() {
    $el.addClass('loading');
  };

  var removeLoadingClass = function removeLoadingClass() {
    $el.removeClass('loading');
  };

  $(function() {
    $el = $('.js-batch-authority-search');
    BatchAuthoritySearch.$el = $el;

    $el.on(Events.loading, addLoadingClass);
    $el.on(Events.loadingComplete, removeLoadingClass);
  });
})(window.jQuery, window.AlaveteliPro);
