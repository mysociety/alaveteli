(function($, BatchAuthoritySearch, DraftBatchSummary, BatchMode) {
  var SearchEvents = BatchAuthoritySearch.Events;
  var DraftEvents = DraftBatchSummary.Events;
  var BatchModeEvents = BatchMode.Events;

  var $search,
      $draft
      $batchMode;

  // var tabs = $modeSwitcher.find('.tab-title');

  // Update the current draft so that users can switch modes without losing
  // their selection of authorities.
  var updateDraftId = function updateDraftId() {
    console.log("MY updateDraftId");

    var $draftId = $('.js-draft-id');
    DraftBatchSummary.draftId = $(summarySelector, $draft).data('draft-id');

    if (DraftBatchSummary.draftId) {
      if ($draftId.val() === '') {
        $('.js-draft-id').val(DraftBatchSummary.draftId);
        $tabs.find('a').attr('href', function() {
          return $(this).attr('href') + "&draft_id=" + DraftBatchSummary.draftId
        });
      };
    };
  };

  $(function() {
    $search = BatchAuthoritySearch.$el;
    $draft = DraftBatchSummary.$el;
    $batchMode = BatchMode.$el;

    $draft.on(DraftEvents.bodyAdded, updateDraftId);
    $search.on(SearchEvents.rendered, updateDraftId);
  });
})(window.jQuery,
   window.AlaveteliPro.BatchAuthoritySearch,
   window.AlaveteliPro.DraftBatchSummary,
   window.AlaveteliPro.BatchMode);
