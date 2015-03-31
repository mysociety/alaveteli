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

  // Remove button removes form div for holiday from an import set
  $('.remove-holiday').each(function(index){
    $(this).click(function(){
      $(this).parents('.import-holiday-info').remove();
      return false;
    });
  });

  if ($('#holiday_import_source_suggestions').is(':checked')){
    $('#holiday_import_ical_feed_url').attr("disabled", "disabled");
  }
  // Enable and disable the feed element when that is selected as the import source
  $('#holiday_import_source_feed').click(function(){
    $('#holiday_import_ical_feed_url').removeAttr("disabled");
  });

  $('#holiday_import_source_suggestions').click(function(){
    $('#holiday_import_ical_feed_url').attr("disabled", "disabled");
  });

});
