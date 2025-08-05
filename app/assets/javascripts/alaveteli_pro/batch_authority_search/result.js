// Handles individual items in the search results list
(function($, BatchAuthoritySearch, DraftBatchSummary) {
  BatchAuthoritySearch.Result = {};
  var SearchEvents = BatchAuthoritySearch.Events;
  var DraftEvents = DraftBatchSummary.Events;
  var $search,
      $results,
      $draft;
  var resultSelector = '.js-batch-authority-search-results-list-item';
  var formSelector = '.js-add-authority-to-batch-form';
  var submitButtonSelector = '.js-add-authority-to-batch-submit';
  var addedClass = 'js-batch-authority-search-results-list-item--added';

  // Lock the search results so that people can't add them whilst a search
  // is ongoing
  var lock = function lock() {
    $results.find(submitButtonSelector)
            .prop('disabled', true)
            .attr('aria-disabled', true);
  };

  // Unlock the search results so that people can add them again
  var unlock = function unlock() {
    $results.find(submitButtonSelector)
            .prop('disabled', false)
            .removeAttr('aria-disabled');
  };

  // Submit the "add body to draft" form via AJAX
  var submitAddForm = function submitAddForm(e) {
    e.preventDefault();
    var $this = $(this);
    DraftBatchSummary.startNewXHR();
    DraftBatchSummary.currentXHR = $.ajax({
      url: $this.attr('action'),
      type: $this.attr('method'),
      dataType: 'html',
      data: $this.serialize()
    });
    // Trigger the usual AJAX events
    DraftBatchSummary.bindXHR();
    // Trigger an additional "Body added" event, we pass the form and the id
    // of the body concerned as a representation of the body that was added.
    DraftBatchSummary.currentXHR.done(function() {
      $draft.trigger(
        DraftEvents.bodyAdded,
        {$form: $this, bodyId: $this.data('body-id')}
      );
    });
    return false;
  };

  // Bind clicks on "add body to draft" buttons, in a function because these
  // get reloaded with new search results.
  var bindAddButtons = function bindAddButtons() {
    $(formSelector, $results).on('submit', submitAddForm);
  };

  // Add/Remove a result from the list after a successful AJAX submission of
  // the add body form or the remove body form.
  // NOTE: what 'adding/removing' actually means is TBD, for now just swaps
  // the form for a piece of text to say it's already added by toggling a
  // class.
  var toggleResultDisplay = function toggleResultDisplay(e, data) {
    $results.find(resultSelector).removeClass(addedClass).filter(function() {
      return DraftBatchSummary.bodiesIds.indexOf($(this).data('body-id')) >= 0;
    }).addClass(addedClass);
  };

  $(function(){
    $search = BatchAuthoritySearch.$el;
    $results = BatchAuthoritySearch.Results.$el;
    $draft = DraftBatchSummary.$el;

    $search.on(SearchEvents.loading, lock);
    $search.on(SearchEvents.rendered, bindAddButtons);
    $search.on(SearchEvents.loadingComplete, unlock);

    $draft.on(DraftEvents.loading, lock);
    $draft.on(DraftEvents.loadingComplete, unlock);

    $draft.on(DraftEvents.bodyAdded, toggleResultDisplay);
    $draft.on(DraftEvents.bodyRemoved, toggleResultDisplay);

    bindAddButtons();
  });
})(window.jQuery,
   window.AlaveteliPro.BatchAuthoritySearch,
   window.AlaveteliPro.DraftBatchSummary);
