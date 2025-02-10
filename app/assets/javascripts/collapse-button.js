$(document).ready(function() {
  const collapseButtons = $('.js-collapse-trigger');
  
  collapseButtons.each(function() {
      const $trigger = $(this);
      const $content = $trigger.next('.js-collapse-content');
      
      // Set initial state
      $content.attr('hidden', true);
      
      $trigger.on('click', function() {
          const isExpanded = $trigger.attr('aria-expanded') === 'true';

          $trigger.attr('aria-expanded', !isExpanded);

          // Toggle visibility
          if (isExpanded) {
              $content.attr('hidden', true);
              $content.slideUp(300);
          } else {
              $content.removeAttr('hidden');
              $content.slideDown(300);
          }
      });
  });
});
