(function($){
  $(function(){
    var $checkboxes = $('.js-show-batch-requests');
    $checkboxes.on('change', function() {
      var $checkbox = $(this);
      var $label = $('label[for="' + $checkbox.attr('id') + '"]');
      var showLabelText = $checkbox.data('show-label');
      var hideLabelText = $checkbox.data('hide-label');
      if(this.checked) {
        $label.text(hideLabelText);
      } else {
        $label.text(showLabelText);
      }
    });
  });
})(window.jQuery);
