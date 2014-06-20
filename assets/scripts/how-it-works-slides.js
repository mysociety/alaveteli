$(function(){
  var $container = $('div.how-does-it-work')

  if(!$container.length){
    return false; // bail out early if no slider on this page
  }

  var showSlide = function(index){
    $('.how-does-it-work__slide:nth-child(' + (index+1) + ')', $container)
    .show().siblings('.how-does-it-work__slide').hide()

    $('.how-does-it-work__slide__skip:nth-child(' + (index+1) + ')', $container)
      .addClass('active').siblings('.how-does-it-work__slide__skip').removeClass('active')
  }

  var makeSlideNavs = function(){
    var $slides = $('.how-does-it-work__slide', $container)
    var $nav = $('<div class="how-does-it-work__slide__nav">')
    for(var i=0; i<$slides.length; i++){
      $('<span class="how-does-it-work__slide__skip">').append('<span>')
        .appendTo($nav)
    }
    $('.container', $slides).append($nav)
  }

  makeSlideNavs()
  showSlide(0)

  $container.on('click', '.how-does-it-work__slide__skip', function(){
    showSlide( $(this).prevAll().length )
  })
});
