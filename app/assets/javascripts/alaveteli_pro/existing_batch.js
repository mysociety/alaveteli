$(function() {
  $('#ignore_existing_batch').change(function() {
    if ($(this).prop('checked')) {
      $('#submit_button').removeAttr('disabled', '');
    } else {
      $('#submit_button').attr('disabled', 'disabled');
    }
  }).change();
});
