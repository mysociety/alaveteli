var $moreMenuLink = $('.js-more-menu-link > a');
var $moreMenu = $('.js-more-menu');
$(function(){
  $moreMenuLink.click(function(e){
    e.preventDefault();
    $moreMenu.slideToggle(250);
    return false;
  });
});
