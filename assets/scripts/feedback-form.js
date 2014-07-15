$( document ).ready(function( $ ) {

    window.setTimeout(function(){
      if ( $('#feedback_form').length ) {
        lastAnswered = $.cookie('survey');
        current = $('input[name="question_no"]').attr('value');
        if ( lastAnswered == null || lastAnswered < current ) {
          $('#feedback_form').show('slow');
        }
      }
    }, 2000);

  // Set the current url to a hidden form value
  $("#feedback_form #url").val(window.location.pathname);

  // Hide the form - don't show for 30 days
  $("#hide_survey").click(function(event){
    $('#feedback_form').hide('slow');
    set_survey_cookie();
    event.preventDefault();
  });

  function set_survey_cookie(){
     // Set the cookie to show that the survey has been answered
    $.cookie('survey', current, { expires: 30, path: '/' });
  }

  // variable to hold request
  var request;
  // bind to the submit event of our form
  $("#feedback_form").submit(function(event){
    // abort any pending request
    if (request) {
      request.abort();
    }
    // setup some local variables
    var $form = $(this);
    // let's select and cache all the fields
    var $inputs = $form.find("input, select, button, textarea");
    // serialize the data in the form
    var serializedData = $form.serialize();

    // let's disable the inputs for the duration of the ajax request
    // Note: we disable elements AFTER the form data has been serialized.
    // Disabled form elements will not be serialized.
    $inputs.prop("disabled", true);
    $('#result').text('Sending data...');

    // fire off the request to /form.php
    request = $.ajax({
      url: "https://script.google.com/macros/s/AKfycbyC2oAdyaAY3StdEKX5zKOln9vt-HX1Eq05nqPmAgUPcpkzqY2K/exec",
      type: "post",
      data: serializedData
    });

    // callback handler that will be called on success
    request.done(function (response, textStatus, jqXHR){
      // log a message to the console
      $('#result').html('Thanks for helping us improve!');
      $('#feedback_form #form_elements').hide('slow');
      $('#feedback_form input[type=submit]').hide('slow');
    });

    // callback handler that will be called on failure
    request.fail(function (jqXHR, textStatus, errorThrown){
      // log the error to the console
      console.error(
        "The following error occured: "+
        textStatus, errorThrown
      );
    });

    // callback handler that will be called regardless
    // if the request failed or succeeded
    request.always(function () {
      // reenable the inputs
      $inputs.prop("disabled", false);
      set_survey_cookie();
    });

    // prevent default posting of form
    event.preventDefault();
  });
});
