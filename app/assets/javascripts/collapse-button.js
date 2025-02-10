// collapse.js
$(document).ready(function() {
    const collapseButtons = $('.js-collapse-trigger');
    
    collapseButtons.each(function() {
        const $trigger = $(this);
        const $content = $trigger.next('.js-collapse-content');

        // This section is for the content inside .js-collapse-content when it has input elements. The idea is to detect if the user is using the fields inside. If he is, then when the page reloads, the .js-collapse-content will be open, and the user will be able to see the active fields and change/clear them instead of having to reopen the collapsed content to be able to change them again. This would be more helpful, especially for users who are making multiple searches.
        // Check if any inputs in the content area have values that match URL parameters
        function hasActiveInputs() {
            const urlParams = new URLSearchParams(window.location.search);
            const inputs = $content.find('input, select, textarea');
            
            return inputs.toArray().some(input => {
                const paramValue = urlParams.get(input.name);
                return paramValue !== null && paramValue !== '';
            });
        }

        // Set initial state based on inputs
        const shouldBeOpen = hasActiveInputs();
        $content.attr('hidden', !shouldBeOpen);
        $trigger.attr('aria-expanded', shouldBeOpen);

        if (shouldBeOpen) {
            $content.show();
        }

        $trigger.on('click', function() {
            const isExpanded = $trigger.attr('aria-expanded') === 'true';
            
            // Toggle aria-expanded
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

        // This an optional feature in case the content inside js-collapse-content has input fields and easier to reset them.
        const $clearButton = $content.find('.js-clear-collapse-section');
        $clearButton.on('click', function(e) {
            e.preventDefault();
            
            // Find all form inputs within this specific collapse content
            const $inputs = $content.find('input, select, textarea');
            
            // Clear each input
            $inputs.each(function() {
                const $input = $(this);
                
                switch($input.prop('type')) {
                    case 'text':
                    case 'date':
                    case 'datetime-local':
                    case 'email':
                    case 'number':
                    case 'tel':
                    case 'time':
                    case 'url':
                    case 'search':
                        $input.val('');
                        break;
                    case 'checkbox':
                    case 'radio':
                        $input.prop('checked', false);
                        break;
                    case 'select-one':
                    case 'select-multiple':
                        $input.prop('selectedIndex', 0);
                        break;
                }
            });

            $content.closest('form').submit();
        });
    });
});

/* 
Usage here:

<div class="collapse-wrapper">
  <!-- Trigger button -->
  <button class="js-collapse-trigger button" 
          aria-expanded="false"
          aria-controls="collapse-1"
          id="trigger-1">
    Advanced Filters
  </button>

  <!-- Collapsible content -->
  <div class="js-collapse-content collapse-content" 
       id="collapse-1"
       role="region" 
       aria-labelledby="trigger-1"
       hidden>

    <!-- Your form fields -->
    <div class="list-filter-item">
      <label for="date-from">From:</label>
      <input type="date" id="date-from" name="date_from">
      
      <label for="date-to">To:</label>
      <input type="date" id="date-to" name="date_to">
    </div>

    <!-- Optional in case there input fields inside the form -->
    <button type="button" class="js-clear-section">
      Clear Filters
    </button>
  </div>
</div>

*/
