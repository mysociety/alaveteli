var setUpCorrespondenceCollapsing = function(){
  $('.js-collapsable').each(function(){
    var $collapsable = $(this);
    var $triggers = $(this).find('.js-collapsable-trigger');
    var $correspondenceHeader = $(this).find('.correspondence__header');

    // Set the default state of the triggers.
    $triggers.attr({
      'role': 'button',
      'tabindex': 0,
      'aria-expanded': function(){
        return $collapsable.is('.collapsed') ? 'false' : 'true';
      },
      'aria-controls': $collapsable.attr('id')
    });

    // Make spacebar / enter on triggers work the same as click.
    // (We would get this for free if we used an actual <button>.)
    $triggers.on('keypress', function(e){
      if (e.keyCode === 13 || e.keyCode === 32) {
        e.preventDefault();
        $(this).trigger('click');
      }
    });

    // Collapse/uncollapse when the trigger is clicked.
    $triggers.on('click', function(){
      $collapsable.trigger('collapse');
    });

    // Listen for the "collapse" event on the collapsable.
    $collapsable.on('collapse', function(){
      $collapsable.toggleClass('collapsed');
      $triggers.attr({
        'aria-expanded': function(){
          return $collapsable.is('.collapsed') ? 'false' : 'true';
        }
      });
    });

    // If the collapsable unit includes a .correspondence__header
    // (it will), then we want that to act as a proxy for the trigger.
    // Clicks anywhere on the header (but not its children) should
    // toggle the collapse, and hovers into / out of the header (but
    // not its children) should give visual feedback.
    $correspondenceHeader.on('click', function(e){
      if (e.target === this) {
        $triggers.eq(0).trigger('click');
      }
    }).on('mouseover', function(e){
      if (e.target === this) {
        $(this).addClass('hovered');
      }
    }).on('mouseout', function(e){
      if (e.target === this) {
        $(this).removeClass('hovered');
      }
    });

    // Likewise, we want the .correspondence__header to show visual
    // feedback if any of the triggers are hovered too.
    $triggers.on('mouseover', function(e){
      if (e.target === this) {
        $correspondenceHeader.addClass('hovered');
      }
    }).on('mouseout', function(e){
      if (e.target === this) {
        $correspondenceHeader.removeClass('hovered');
      }
    });
  });
};
