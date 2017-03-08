(function($){
  $(function(){
    var $search = $('.js-batch-authority-search');
    var $form = $('.js-batch-authority-search-form');
    var $query = $('.js-batch-authority-search-form-query');
    var $draftId = $('.js-batch-authority-search-form-draft-id');
    var $results = $('.js-batch-authority-search-results');

    var paginationSelector = '.pagination a';
    var searchResultsButtonSelector = '.js-add-authority-to-batch-submit';
    var draftId = $draftId.length > 0 ? $draftId.val() : null;

    var loadingEvent = 'alaveteliPro:batch:results:loading';
    var loadingSuccessEvent = 'alaveteliPro:batch:results:loadingSuccess';
    var loadingErrorEvent = 'alaveteliPro:batch:results:loadingError';
    var loadingCompleteEvent = 'alaveteliPro:batch:results:loadingComplete';

    var currentXHR;

    // Submit the search form via ajax, either with provided data, or
    // extracting the data from the form fields.
    // Triggers custom events on the main search container when loading starts
    // when it succeeds or errors, and when it's definitely complete either
    // way.
    // Note that this maintain a record of requests made and aborts any
    // existing ones before starting a new one.
    var submitForm = function submitForm(e, data) {
      e.preventDefault();
      $search.trigger(loadingEvent);
      if (currentXHR) {
        currentXHR.abort();
      }
      var formData = getFormData(data);
      currentXHR = $.ajax({
        url: $form.attr('action'),
        type: $form.attr('method'),
        dataType: 'html',
        data: formData
      });
      currentXHR.done(function(data) {
        $search.trigger(loadingSuccessEvent, {html: data});
      });
      currentXHR.fail(function() {
        $search.trigger(loadingErrorEvent);
      });
      currentXHR.always(function() {
        $search.trigger(loadingCompleteEvent);
      });
      return false;
    };

    // Extract form data from the supplied object or the HTML form.
    // We can't just serialize the form because we add a value attribute to
    // the query field which jQuery will use instead of the actual current
    // value.
    var getFormData = function getFormData(data) {
      var formData;
      if(typeof data === 'undefined') {
        formData = { query: $query.val() };
        if(draftId !== null) {
          formData.draftId = draftId;
        }
      } else {
        formData = data;
      }
      return formData;
    };

    // Update the displayed results
    var updateResults = function updateResults(e, data) {
      $results.html(data.html);
    };

    // Show an error message when AJAX loading failed
    var showLoadingError = function showLoadingError() {
      $results.html($results.data('ajax-error-message'));
    };

    var addLoadingClass = function startLoading() {
      $search.addClass('loading');
    };

    var removeLoadingClass = function finishLoading() {
      $search.removeClass('loading');
    };

    // Lock the search results so that people can't add them whilst a search
    // is ongoing
    var lockResults = function lockResults() {
      $results.find(searchResultsButtonSelector)
              .prop('disabled', true)
              .attr('aria-disabled', true);
    };

    // Unlock the search results so that people can add them again
    var unlockResults = function unlockResults() {
      $results.find(searchResultsButtonSelector)
              .prop('disabled', false)
              .removeAttr('aria-disabled');
    };

    // Lock the pagination links so that people can't use them whilst a search
    // is going on.
    var lockPagination = function lockPagination() {
      $(paginationSelector).addClass('disabled')
                           .attr('aria-disabled', true);
    };

    // Unlock the pagination links so that people can use them again
    var unlockPagination = function lockPagination() {
      $(paginationSelector).removeClass('disabled')
                           .removeAttr('aria-disabled');
    };

    // Bind click events on the pagination links, which get reloaded with new
    // search results, hence this being in a function.
    var bindPagination = function bindPagination() {
      $(paginationSelector).on('click', function(e) {
        var $this = $(this);
        e.preventDefault();
        // Clicks on disabled links just get ignored
        if(!$this.hasClass('disabled')) {
          // Parse the data we'll submit with the form from the link url
          var querystring = $this.attr('href').split('?')[1];
          var params = $.deparam(querystring);
          submitForm(e, params);
        }
        return false;
      });
    };

    $search.on(loadingEvent, addLoadingClass);
    $search.on(loadingEvent, lockResults);
    $search.on(loadingEvent, lockPagination);

    $search.on(loadingSuccessEvent, updateResults);
    $search.on(loadingSuccessEvent, bindPagination);

    $search.on(loadingErrorEvent, showLoadingError);

    $search.on(loadingCompleteEvent, removeLoadingClass);
    $search.on(loadingCompleteEvent, unlockResults);
    $search.on(loadingCompleteEvent, unlockPagination);

    $form.on('submit', submitForm);
    // We debounce this because otherwise it'll send (and then abort) a new
    // request for every keystroke, which would hammer the server
    $query.on('keypress', $.debounce(500, submitForm));

    bindPagination();
  });
})(window.jQuery);
