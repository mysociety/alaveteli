$(function(){
  $('[data-length-monitor-selector]').each(function(){
    var $display = $(this);
    var get = function(setting) {
      return $display.attr('data-length-monitor-' + setting);
    };

    var $textarea = $( get('selector') );

    var levels = [{
      threshold: 0,
      css: 'text-length-s',
      message: ''
    }];

    if ( get('threshold-l') && get('message-l')) {
      levels.push({
        threshold: get('threshold-l'),
        css: 'text-length-l',
        message: get('message-l')
      });
    }

    if ( get('threshold-xl') && get('message-xl')) {
      levels.push({
        threshold: get('threshold-xl'),
        css: 'text-length-xl',
        message: get('message-xl')
      });
    }

    // Sort thresholds from longest to shortest. This allows us to loop
    // through them, from longest to shortest, and break out of the loop
    // as soon as we find a threshold longer than the $textarea length.
    levels.sort(function (a, b) {
      return b.threshold - a.threshold;
    });

    // Keep track of current level, so we can know specifically when to
    // manipulate the DOM, rather than doing it on every keyup event.
    var currentLevel = 0;

    // Construct a list of all the classes we'll be applying to the
    // $display element, so we can remove them all in one go.
    var allClasses = [];
    for (var i=0; i<levels.length; i++) {
      allClasses.push(levels[i].css);
    }
    var allClasses = allClasses.join(' ');

    var updateDisplay = function() {
      var length = $textarea.val().length;

      for (var i=0; i<levels.length; i++) {
        if ( length >= levels[i].threshold ) {
          if ( currentLevel !== levels[i].threshold ) {
            $display.html( levels[i].message );
            $display.removeClass(allClasses);
            $display.addClass(levels[i].css);
            currentLevel = levels[i].threshold;
          }
          break;
        }
      }
    };

    $textarea.on('keyup change', updateDisplay);
    updateDisplay();
  });
});
