(function($){
  $(function(){
    var $expiry = $('.js-embargo-expiry');
    var $durationSelect = $('.js-embargo-duration');
    $('.js-embargo-form').change(function() {
      if($durationSelect.val() !== '') {
        var expiryDate = $durationSelect.find('option:selected').data('expiry-date');
        $expiry.text(expiryDate);
        $(this).submit();
      }
    });
  });
})(window.jQuery);
