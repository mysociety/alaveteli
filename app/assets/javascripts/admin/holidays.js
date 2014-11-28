$(function() {

  // New button loads the 'new' form via AJAX
  $('#new-holiday-button').click(function(){
    var new_call = $.ajax({ type: 'GET', url: $(this).attr('href')});
    new_call.done(function(response) {
      $('#existing-holidays').before(response);
    });
    return false;

  });

  // Each edit button loads the 'edit' form for that holiday via AJAX
  $('.holiday').each(function(index){
    var holiday_row = $(this);
    var edit_button = holiday_row.find('.edit-button');

    edit_button.click(function(){
      var edit_call = $.ajax({ type: 'GET', url: holiday_row.data('target') });

      edit_call.done(function(response) {
        holiday_row.html(response);
      });
      return false;
    });
  });
});
