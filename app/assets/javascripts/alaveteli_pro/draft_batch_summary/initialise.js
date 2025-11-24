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
    hadReachedLimit: namespace + ':hadReachedLimit',
    updatedDraftID: namespace + ':updatedDraftID'
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

  DraftBatchSummary.urlWithDraftID = function(url) {
    // Parse the url so that we can modify the draft_id param
    var urlParts = url.split('?');
    var path = urlParts[0];
    var querystring = urlParts[1];
    var params = $.deparam(querystring);

    // 1. There is a DraftBatchSummary.draftId, but there is no draft_id param
    // in the url, so we want to add the param.
    //
    // 2. There is a DraftBatchSummary.draftId, and we have an existing
    // draft_id param in the url, so we want to update it to make sure we're
    // using the current DraftBatchSummary.draftId.
    //
    // 3. There is no DraftBatchSummary.draftId, but we have a draft_id param
    // in the url, so we want to remove the draft_id param.
    if (DraftBatchSummary.draftId) {
      params.draft_id = DraftBatchSummary.draftId;
    } else if (params.draft_id) {
      delete params.draft_id;
    }

    return path + '?' + $.param(params);
  }

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
