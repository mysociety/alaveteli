(function($){
  $(function(){
    var $expiry = $('.js-embargo-expiry');
    var $durationSelect = $('.js-embargo-duration');
    var $form = $('.js-embargo-form');
    var $submit = $('.js-embargo-submit', $form);
    var $active = $('.js-embargo-active');
    var $inactive = $('.js-embargo-inactive');
    $durationSelect.change(function() {
      if($(this).val() !== '') {
        var expiryDate = $(this).find('option:selected').data('expiry-date');
        $expiry.text(expiryDate);
        $active.show();
        $inactive.hide();
        if(typeof $submit.data('confirm') === 'undefined' || window.confirm($submit.data('confirm'))) {
          $form.submit();
        }
      } else if ($form.length == 0) {
        $active.hide();
        $inactive.show();
      }
    }).change();
  });
})(window.jQuery);
