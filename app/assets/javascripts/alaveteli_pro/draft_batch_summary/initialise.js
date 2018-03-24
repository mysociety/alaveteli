// Handles the summary pane for the draft batch request
// (the selected authorities; pane on the right)
// TODO: Shares an awful lot with BatchAuthoritySearch - refactor into a base
// class?
(function($, AlaveteliPro) {
  var DraftBatchSummary = AlaveteliPro.DraftBatchSummary = {};
  var $el;
  var namespace = AlaveteliPro.Events.namespace + ':DraftBatchSummary';
  var Events = DraftBatchSummary.Events = {
    namespace: namespace,
    loading: namespace + ':loading',
    loadingSuccess: namespace + ':loadingSuccess',
    loadingError: namespace + ':loadingError',
    loadingComplete: namespace + ':loadingComplete',
    bodyAdded: namespace + ':bodyAdded',
    bodyRemoved: namespace + ':bodyRemoved',
    reachedLimit: namespace + ':reachedLimit',
    hadReachedLimit: namespace + ':hadReachedLimit'
  };

  // Start a new XHR request, aborts any existing one and triggers a loading
  // event on the root element to tell everything about it.
  DraftBatchSummary.startNewXHR = function startNewXHR() {
    if (DraftBatchSummary.currentXHR) {
      DraftBatchSummary.currentXHR.abort();
    }
    $el.trigger(Events.loading);
  };

  // Bind to the various outcomes of the currentXHR so that we trigger the
  // right events when things happen with it
  DraftBatchSummary.bindXHR = function bindXHR() {
    DraftBatchSummary.currentXHR.done(function(data) {
      $el.trigger(Events.loadingSuccess, {html: data});
    });
    DraftBatchSummary.currentXHR.fail(function(xhr, textStatus) {
      $el.trigger(Events.loadingError, {textStatus: textStatus});
    });
    DraftBatchSummary.currentXHR.always(function() {
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
    $el = $('.js-draft-batch-request');
    DraftBatchSummary.$el = $el;

    $el.on(Events.loading, addLoadingClass);
    $el.on(Events.loadingComplete, removeLoadingClass);
  });
})(window.jQuery, window.AlaveteliPro);
