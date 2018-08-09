(function($){


    $('.js-request-navigation').each(function() {
        var $requestNav = $(this);

        var statusText = $(this).attr('data-status-text');
        var nextText = $(this).attr('data-next-text');
        var prevText = $(this).attr('data-prev-text');

        var $allCorrespondence = $('.correspondence');
        var currentCorrespondenceIndex = 0;
        var correspondenceIds = [];

        var adminBarHeight = $('.admin .navbar-fixed-top').outerHeight() || 0;
        
        $allCorrespondence.each(function() {
            correspondenceIds.push($(this).attr('id'));
        });

        var updateStatusText = function updateStatusText() {
            if(window.location.hash) {
                var i = correspondenceIds.indexOf(window.location.hash.substr(1)); 
                // make sure the URL fragment refers to a correspondence element
                if(i > -1) {
                    currentCorrespondenceIndex = i;
                }
            } 
            $navStatus.text(
                statusText.replace('[[x]]', currentCorrespondenceIndex + 1).replace('[[y]]', $allCorrespondence.length)
            );
        }

        var scrollToCurrentCorrespondence = function scrollToCurrentCorrespondence() {
            var $el = $('#' + correspondenceIds[currentCorrespondenceIndex]);
            $('html, body').animate({
                scrollTop: $el.offset().top - adminBarHeight
            }, 150);

        }

        var nextCorrespondence = function nextCorrespondence() {
            currentCorrespondenceIndex = Math.min(currentCorrespondenceIndex + 1, correspondenceIds.length - 1);
            scrollToCurrentCorrespondence();
        }

        var prevCorrespondence = function prevCorrespondence() {
            currentCorrespondenceIndex = Math.max(currentCorrespondenceIndex - 1, 0);
            scrollToCurrentCorrespondence();
        }

        var $prevButton = $('<button>').text(prevText).on('click', prevCorrespondence);
        var $nextButton = $('<button>').text(nextText).on('click', nextCorrespondence);

        var $navStatus = $('<button>').on('click', scrollToCurrentCorrespondence);
        updateStatusText();

        $requestNav.append($prevButton, $nextButton, $navStatus);

        window.addEventListener('hashchange', updateStatusText);

    });


})(window.jQuery);