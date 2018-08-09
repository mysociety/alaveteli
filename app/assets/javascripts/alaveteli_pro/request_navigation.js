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

        var updateCurrentCorrespondenceIndex = function updateCurrentCorrespondenceIndex() {
            if(window.location.hash) {
                var i = correspondenceIds.indexOf(window.location.hash.substr(1)); 
                // make sure the URL fragment refers to a correspondence element
                if(i > -1) {
                    currentCorrespondenceIndex = i;
                }
            } 
        }

        var highlightCurrentCorrespondence = function highlightCurrentCorrespondence() {
            $('.correspondence--current').removeClass('correspondence--current');
            $('#' + correspondenceIds[currentCorrespondenceIndex]).addClass('correspondence--current');
        }

        var updateStatusText = function updateStatusText() {
            $navStatus.text(
                statusText.replace('[[x]]', currentCorrespondenceIndex + 1).replace('[[y]]', $allCorrespondence.length)
            );
        }

        var scrollToCurrentCorrespondence = function scrollToCurrentCorrespondence() {
            var $el = $('#' + correspondenceIds[currentCorrespondenceIndex]);
            $('html, body').stop().animate({
                scrollTop: $el.offset().top - adminBarHeight
            }, 150);
        }

        var nextCorrespondence = function nextCorrespondence() {
            history.pushState({}, null, '#' + correspondenceIds[Math.min(currentCorrespondenceIndex + 1, correspondenceIds.length - 1)]);
            updateCurrentCorrespondenceIndex();
            updateStatusText();
            scrollToCurrentCorrespondence();
            highlightCurrentCorrespondence();
        }

        var prevCorrespondence = function prevCorrespondence() {
            history.pushState({}, null, '#' + correspondenceIds[Math.max(currentCorrespondenceIndex - 1, 0)]);
            updateCurrentCorrespondenceIndex();
            updateStatusText();
            scrollToCurrentCorrespondence();
            highlightCurrentCorrespondence();
        }

        var $prevButton = $('<button>').text(prevText).on('click', prevCorrespondence);
        var $nextButton = $('<button>').text(nextText).on('click', nextCorrespondence);

        var $navStatus = $('<button>').on('click', scrollToCurrentCorrespondence);
        updateCurrentCorrespondenceIndex();
        updateStatusText();
        if(correspondenceIds.indexOf(window.location.hash.substr(1)) > -1) {
            scrollToCurrentCorrespondence();
            highlightCurrentCorrespondence();
        }


        $requestNav.append($prevButton, $nextButton, $navStatus);

        window.addEventListener('hashchange', function(event) {
            if(correspondenceIds.indexOf(window.location.hash.substr(1)) > -1) {
                event.preventDefault();
                updateCurrentCorrespondenceIndex();
                updateStatusText();
                scrollToCurrentCorrespondence();
                highlightCurrentCorrespondence();
            }
        });

    });


})(window.jQuery);