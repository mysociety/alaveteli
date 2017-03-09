// Handles submission of the search form via ajax
(function($, BatchAuthoritySearch){
  BatchAuthoritySearch.SearchForm = {};
  var $search,
      $form,
      $query,
      $draftId,
      draftId;

  // Submit the search form via AJAX.
  var submitForm = function submitForm(e) {
    e.preventDefault();
    BatchAuthoritySearch.startNewXHR();
    var formData = { query: $query.val() };
    if(draftId !== null) {
      formData.draftId = draftId;
    }
    BatchAuthoritySearch.currentXHR = $.ajax({
      url: $form.attr('action'),
      type: $form.attr('method'),
      dataType: 'html',
      data: formData
    });
    BatchAuthoritySearch.bindXHR();
    return false;
  };

  $(function(){
    $search = BatchAuthoritySearch.$el;
    $form = $('.js-batch-authority-search-form');
    $query = $('.js-batch-authority-search-form-query');
    $draftId = $('.js-batch-authority-search-form-draft-id');
    draftId = $draftId.length > 0 ? $draftId.val() : null;

    BatchAuthoritySearch.SearchForm.$el = $form;

    $form.on('submit', submitForm);
    // We debounce this because otherwise it'll send (and then abort) a new
    // request for every keystroke, which would hammer the server
    $query.on('keypress', $.debounce(500, submitForm));
  });
})(window.jQuery, window.AlaveteliPro.BatchAuthoritySearch);
