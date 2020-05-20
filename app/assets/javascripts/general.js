$(document).ready(function() {
 // flash message for people coming from other countries
 var htmlWrapperFront = [
                          '<div class="popup popup--popup popup--locality" role="alert" id="locality-popup">',
                          ' <div class="row">',
                          '   <div class="popup__content">',
                        ];
 var htmlWrapperBack = [
                          '     <a href="#top" class="popup__close js-popup__close" aria-label="close">',
                          '       <span aria-hidden="true">&times;</span>',
                          '     </a>',
                          '   </div>',
                          ' </div>',
                          '</div>',
                        ];
var wholeMessage = '';
if(window.location.search.substring(1).search("country_name") == -1) {
  if (!$.cookie('has_seen_country_message')) {
    $.ajax({
      url: "/country_message",
      dataType: 'html',
      success: function(country_message){
        if (country_message != ''){
          wholeMessage = htmlWrapperFront.join('') + country_message + htmlWrapperBack.join('');
          $('#country-message').html(wholeMessage);
          $('body:not(.front) #locality-popup').show()
        }
        $('#locality-popup .js-popup__close').click(function() {
          $('#locality-popup').hide('slow');
          $.cookie('has_seen_country_message', 1, {expires: 365, path: '/'});
          return false;
        });
      }
    })
  }
}

 // popups
$('#standard-popup .js-popup__close').click(function() {
  $('#standard-popup').hide('slow');
});


  // "link to this" box
  $('.cplink__button').click(function() {
    var box = $(this).prev('.cplink__field');
    box.select();
  });


     $('.close-button').click(function() { $(this).parent().hide() });
     $('div#variety-filter a').each(function() {
       $(this).click(function() {
         var form = $('form#search_form');
         form.attr('action', $(this).attr('href'));
         form.submit();
         return false;
     })
   })

  // "Create widget" page
  $("#widgetbox").select()
  // Chrome workaround
  $("widgetbox").mouseup(function() {
    // Prevent further mouseup intervention
    $this.unbind("mouseup");
    return false;
  });

  $('.js-toggle-delivery-log').on('click', function(e){
    e.preventDefault();

    var $correspondence = $(this).parents('.correspondence');
    var url = $(this).attr('href');
    var $correspondence_delivery = $correspondence.find('.correspondence_delivery');

    if( $correspondence_delivery.length ){
      removeCorrespondenceDeliveryBox($correspondence_delivery);
    } else {
      loadCorrespondenceDeliveryBox($correspondence, url);
    }
  });

  var loadCorrespondenceDeliveryBox = function loadCorrespondenceDeliveryBox($correspondence, url){
    var $toggle = $correspondence.find('.js-toggle-delivery-log');
    var $correspondence_delivery = $('<div>')
      .addClass('correspondence_delivery')
      .addClass('correspondence_delivery--' + $toggle.attr('data-delivery-status'))
      .hide()
      .insertBefore( $correspondence.find('.correspondence_text') );

    $toggle.addClass('toggle-delivery-log--loading');

    $.ajax({
      url: url,
      dataType: "html"
    }).done(function(html){
      var $deliveryDiv = $(html).find('.controller_delivery_statuses');
      $correspondence_delivery.html( $deliveryDiv.html() );
      $correspondence_delivery.slideDown(200);
    }).fail(function(){
      var msgHtml = $('.js-delivery-log-ajax-error').html();
      $correspondence_delivery.html( msgHtml );
      $correspondence_delivery.slideDown(200);

    }).always(function(){
      $toggle.removeClass('toggle-delivery-log--loading');
    });
  }

  var removeCorrespondenceDeliveryBox = function removeCorrespondenceDeliveryBox($correspondence_delivery){
    $correspondence_delivery.slideUp(200, function(){
      $correspondence_delivery.remove();
    });
  }

  var $accountLink = $('.js-account-link');
  var $accountMenu = $('.js-account-menu');
  $(function(){
    $accountLink.click(function(e){
      e.preventDefault();
      e.stopPropagation();
      $accountMenu.slideToggle(250);
      return false;
    });
    $(document).click( function(){
      // hide the menu when we click off it
      $accountMenu.slideUp(250);
    });
    $accountMenu.click(function(e){
      // but don't hide when we click the menu
      e.stopPropagation();
    });
  });
})


$(document).ready(function() {
  $('.after-actions__action-menu').dropit({
    submenuEl: '.action-menu__menu'
  });

  setUpCorrespondenceCollapsing();
});


// Pro subscription cancellation message controls
$(document).ready(function() {
  $(".js-cancel-subscription__message").toggle();
});

$(".js-control-cancel-subscription__message").click(function(){
  $(".js-cancel-subscription__message").slideToggle( 150 );
});

// Project skip button
$(document).ready(function() {
  //only show if we have JS enabled
  $('.js-project-skip-button').toggle();
});


$('.js-project-skip-button').click(function(){
  window.location.reload(false); 
  return false;
});
