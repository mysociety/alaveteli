$(document).ready(function() {
  $('.batch_public_body_list').hide();
  var showtext = $('.batch_public_body_toggle').attr('data-showtext');
  var hidetext = $('.batch_public_body_toggle').attr('data-hidetext');
  $('.toggle-message').text(showtext);
  $('.batch_public_body_toggle').click(function(){
    $('.batch_public_body_list').toggle();
    if ($('.toggle-message').text() == showtext){
      $('.toggle-message').text(hidetext);
    }else{
      $('.toggle-message').text(showtext);
    }
  })
})
