(function($, DraftBatchSummary, BatchMode) {
  var DraftEvents = DraftBatchSummary.Events;

  var $draft,
      $batch;

  var updateDraftId = function updateDraftId() {
    var $tabs = $batch.find('.tab-title');

    $tabs.find('a').attr('href', function(i, href) {
      // Parse the href so that we can modify the draft_id param
      var urlParts = href.split('?');
      var path = urlParts[0];
      var querystring = urlParts[1];
      var params = $.deparam(querystring);

      // 1. There is a DraftBatchSummary.draftId, but there is no draft_id param
      // in the href, so we want to add the param.
      //
      // 2. There is a DraftBatchSummary.draftId, and we have an existing
      // draft_id param in the href, so we want to update it to make sure we're
      // using the current DraftBatchSummary.draftId.
      //
      // 3. There is no DraftBatchSummary.draftId, but we have a draft_id param
      // in the href, so we want to remove the draft_id param.
      if (DraftBatchSummary.draftId) {
        params.draft_id = DraftBatchSummary.draftId;
      } else if (params.draft_id) {
        delete params.draft_id;
      }

      return path + '?' + $.param(params);
    });
  };

  $(function() {
    $draft = DraftBatchSummary.$el;
    $batch = BatchMode.$el;

    $draft.on(DraftEvents.updatedDraftID, updateDraftId);
  });
})(window.jQuery,
   window.AlaveteliPro.DraftBatchSummary,
   window.AlaveteliPro.BatchMode);
