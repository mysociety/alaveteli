$(document).ready(function() {
 if(window.location.search.substring(1).search("country_name") == -1) {
    if (!$.cookie('has_seen_country_message')) {
	$.ajax({
		url: "/country_message",
		    dataType: 'html',
		    success: function(country_message){
		    if (country_message != ''){
			$('#other-country-notice').html(country_message);
			$('body:not(.front) #other-country-notice').show()
		    }
		}
	    })
	    
     }
 }

 $('#other-country-notice').click(function() {
	 $('#other-country-notice').hide();
	 $.cookie('has_seen_country_message', 1, {expires: 365, path: '/'});
     })
})