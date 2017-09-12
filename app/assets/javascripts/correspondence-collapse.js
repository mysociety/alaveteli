var setUpCorrespondenceCollapsing = function () {
  // React to clicks and hovers on the collapsable triggers, but ignore
  // clicks/hovers from child elements like .correspondence__header__date
  // and .correspondence__header__delivery-status
  $('.js-collapsable-trigger').on('click', function (e) {
    if (e.target == this) {
      $(this).parents('.js-collapsable').toggleClass('collapsed');
    }
  }).on('mouseover', function(e){
    if (e.target == this) {
      $(this).addClass('hovered');
    }
  }).on('mouseout', function(e){
    if (e.target == this) {
      $(this).removeClass('hovered');
    }
  });
};
