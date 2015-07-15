$(document).ready(function() {

  function add_option(selector, value, text) {
    var optionExists = ($(selector + ' option[value=' + value + ']').length > 0);
    if(!optionExists){
      $(selector).append("<option value=" + value + ">" + text + "</option>");
    }
  }
  // Transfer a set of select options defined by 'from_selector' to another select,
  // defined by 'to_selector'
  function transfer_options(from_selector, to_selector){
    $(from_selector).each(function()
    {
      add_option(to_selector, $(this).val(), $(this).text());
      $(this).remove();
    })
    $('#public_body_query').val('');
    return false;
  }

  // Submit the search form once the text reaches a certain length
  $("#public_body_query").keypress($.debounce( 300, function() {
    if ($('#public_body_query').val().length >= 3) {
      $('#body_search_form').submit();
    }
  }));

  // Populate the candidate list with json search results
  $('#body_search_form').on('ajax:success', function(event, data, status, xhr) {
    $('#select_body_candidates').empty();
    $.each(data, function(key, value)
    {
      add_option('#select_body_candidates', value['id'], value['name']);
    });
  });

  // Add a hidden element to the submit form for every option in the selected list
  $('#body_submit_button').click(function(){
    $('#select_body_selections option').each(function()
    {
      $('#body_submit_form').append('<input type="hidden" value="' + $(this).val() + '" name="public_body_ids[]">' );
    })
  })

  // Transfer selected candidates to selected list
  $('#body_select_button').click(function(){
    return transfer_options('#select_body_candidates option:selected', '#select_body_selections');
  })

  // Transfer selected selected options back to candidate list
  $('#body_deselect_button').click(function(){
    return transfer_options('#select_body_selections option:selected', '#select_body_candidates');
  })

  // Transfer all candidates to selected list
  $('#body_select_all_button').click(function(){
    return transfer_options('#select_body_candidates option', '#select_body_selections');
  })

  // Transfer all selected back to candidate list
  $('#body_deselect_all_button').click(function(){
    return transfer_options('#select_body_selections option', '#select_body_candidates');
  })

  // Show the buttons for selecting and deselecting all
  $('.select_all_button').show();
})
