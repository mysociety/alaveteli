(function($){
  $(function(){
    var $expiry = $('.js-embargo-expiry');
    var $durationSelect = $('.js-embargo-duration');
    var $submit = $('.js-embargo-submit');
    $('.js-embargo-form').change(function() {
      if($durationSelect.val() !== '') {
        if(typeof $submit.data('confirm') === 'undefined' || window.confirm($submit.data('confirm'))) {
          var expiryDate = $durationSelect.find('option:selected').data('expiry-date');
          $expiry.text(expiryDate);
          $(this).submit();
        }
      }
    });
  });
})(window.jQuery);
