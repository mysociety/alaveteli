// Handles updating the batch authority search authority count
(function($, BatchAuthoritySearch, DraftBatchSummary) {
  var DraftEvents = DraftBatchSummary.Events;

  var $search,
      $draft,
      $count,
      messageTemplateZero,
      messageTemplateOne,
      messageTemplateMany;

  // Update the count
  var updateCount = function(e) {
    count = publicBodiesCount();
    if (count == 0) { messageTemplate = messageTemplateZero; }
    else if (count == 1) { messageTemplate = messageTemplateOne; }
    else { messageTemplate = messageTemplateMany; }

    $count.text(messageTemplate.replace('{{count}}', count));
  };

  // Return the number of public bodies added
  var publicBodiesCount = function() {
    return $(
      '.js-draft-batch-request-summary .batch-builder__list__item', $draft
    ).length;
  }

  $(function() {
    $search = BatchAuthoritySearch.$el;
    $draft = DraftBatchSummary.$el;
    $count = $('.batch-builder__actions__count', $search);
    messageTemplateZero = $count.data('message-template-zero');
    messageTemplateOne = $count.data('message-template-one');
    messageTemplateMany = $count.data('message-template-many');

    // not count element present, escape before binding events
    if (!$count.get(0)) { return }

    updateCount();

    $draft.on(DraftEvents.bodyAdded, updateCount);
    $draft.on(DraftEvents.bodyRemoved, updateCount);
  });
})(window.jQuery,
   window.AlaveteliPro.BatchAuthoritySearch,
   window.AlaveteliPro.DraftBatchSummary);
