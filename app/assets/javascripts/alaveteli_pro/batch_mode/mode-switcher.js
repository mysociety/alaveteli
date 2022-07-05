(function($, DraftBatchSummary, BatchMode) {
  var DraftEvents = DraftBatchSummary.Events;

  var $draft,
      $batch;

  var updateDraftId = function updateDraftId() {
    var $tabs = $batch.find('.tab-title');

    $tabs.find('a').attr('href', function(i, href) {
      return DraftBatchSummary.urlWithDraftID(href);
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
