// Handles submission of the search form via ajax
(function($, BatchAuthoritySearch, DraftBatchSummary){
  var SearchEvents = BatchAuthoritySearch.Events;
  var DraftEvents = DraftBatchSummary.Events;
  BatchAuthoritySearch.SearchForm = {};
  var $search,
      $draft,
      $form,
      $query,
      currentValue;

  // Submit the search form via AJAX.
  var submitForm = function submitForm(e) {
    if (typeof e !== 'undefined') {
      e.preventDefault();
    }
    BatchAuthoritySearch.startNewXHR();
    var formData = {
      authority_query: $query.val(),
      draft_id: DraftBatchSummary.draftId
    };
    BatchAuthoritySearch.currentXHR = $.ajax({
      url: $form.attr('action'),
      type: $form.attr('method'),
      dataType: 'html',
      data: formData
    }).done(function () {
      currentValue = formData.authority_query;
    });
    BatchAuthoritySearch.bindXHR();
    return false;
  };

  var submitFormIfNeeded = function submitFormIfNeeded() {
    if ($form.is(':visible') &&
        !DraftBatchSummary.hasReachedLimit &&
        $query.val() !== currentValue) {
      submitForm();
    } else {
      $search.trigger(SearchEvents.loadingSuccess);
    }
  }

  $(function(){
    $search = BatchAuthoritySearch.$el;
    $draft = DraftBatchSummary.$el;
    $form = $('.js-batch-authority-search-form', $search);
    $query = $('.js-batch-authority-search-form-query', $search);
    BatchAuthoritySearch.SearchForm.$el = $form;

    $form.on('submit', submitForm);

    // We debounce this because otherwise it'll send (and then abort) a new
    // request for every keystroke, which would hammer the server
    $query.on('keypress', $.debounce(500, submitForm));

    $draft.on(DraftEvents.hadReachedLimit, submitFormIfNeeded);
    submitFormIfNeeded();
  });
})(window.jQuery,
   window.AlaveteliPro.BatchAuthoritySearch,
   window.AlaveteliPro.DraftBatchSummary);
