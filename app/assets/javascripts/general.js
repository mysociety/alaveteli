$(document).ready(function() {
 // flash message for people coming from other countries
 if(window.location.search.substring(1).search("country_name") == -1) {
    if (!$.cookie('has_seen_country_message')) {
  $.ajax({
    url: "/country_message",
        dataType: 'html',
        success: function(country_message){
        if (country_message != ''){
      $('#other-country-notice .popup-content').html(country_message);
      $('body:not(.front) #other-country-notice').show()
        }
    }
      })

     }
 }

 // popup messages
 $('#other-country-notice .popup-close').click(function() {
   $('#other-country-notice').hide('slow');
   $.cookie('has_seen_country_message', 1, {expires: 365, path: '/'});
     });
 $('#everypage .popup-close').click(function() {
   $('#everypage').hide('slow');
   $.cookie('seen_foi2', 1, { expires: 7, path: '/' });
   return false;
   });

  // "link to this" widget
  $('a.link_to_this').click(function() {
    var box = $('div#link_box');
    var location = window.location.protocol + "//" + window.location.hostname + $(this).attr('href');
    box.width(location.length + " em");
    box.find('input').val(location).attr('size', location.length + " em");
    box.show();
    box.position({
      my: "right center",
      at: "left bottom",
      of:  this,
      collision: "fit" });
    box.find('input').select();
    return false;
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

   if($.cookie('seen_foi2') == 1) {
     $('#everypage').hide();
   }

  // "Create widget" page
  $("#widgetbox").select()
  // Chrome workaround
  $("widgetbox").mouseup(function() {
    // Prevent further mouseup intervention
    $this.unbind("mouseup");
    return false;
  });
})
