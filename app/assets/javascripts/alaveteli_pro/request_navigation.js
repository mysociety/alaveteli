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
        var tolerance = 30; //the amount of space between the top of the window and the current correspondence element
        
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

        var disableButtons = function disableButtons() {
            if((currentCorrespondenceIndex + 1 >= correspondenceIds.length) && (currentCorrespondenceIndex <= 0) ) {
                //disable both buttons
                $prevButton.attr('disabled', 'disabled');
                $nextButton.attr('disabled', 'disabled');
            } else if(currentCorrespondenceIndex + 1 >= correspondenceIds.length) {
                //disable next
                $nextButton.attr('disabled', 'disabled');
            } else if (currentCorrespondenceIndex <= 0) {
                //disable prev
                $prevButton.attr('disabled', 'disabled');
            } else {
                $nextButton.removeAttr('disabled');
                $prevButton.removeAttr('disabled');
            }
        }

        var updateUI = function updateUI() {
            updateCurrentCorrespondenceIndex();
            updateStatusText();
            disableButtons();
            if(correspondenceIds.indexOf(window.location.hash.substr(1)) > -1) {
                scrollToCurrentCorrespondence();
                highlightCurrentCorrespondence();
            }
        }

        var scrollToCurrentCorrespondence = function scrollToCurrentCorrespondence() {
            var $el = $('#' + correspondenceIds[currentCorrespondenceIndex]);
            $('html, body').stop().animate({
                scrollTop: $el.offset().top - adminBarHeight - tolerance
            }, 150);
        }

        var nextCorrespondence = function nextCorrespondence() {
            history.pushState({}, null, '#' + correspondenceIds[Math.min(currentCorrespondenceIndex + 1, correspondenceIds.length - 1)]);
            updateUI();
        }

        var prevCorrespondence = function prevCorrespondence() {
            history.pushState({}, null, '#' + correspondenceIds[Math.max(currentCorrespondenceIndex - 1, 0)]);
            updateUI();
        }

        var $prevButton = $('<button>').text(prevText).addClass("request-navigation__button request-navigation__button--prev").on('click', prevCorrespondence);
        var $nextButton = $('<button>').text(nextText).addClass("request-navigation__button request-navigation__button--next").on('click', nextCorrespondence);

        var $navStatus = $('<button>').addClass("request-navigation__button request-navigation__button--current").on('click', scrollToCurrentCorrespondence);
        updateUI();


        $requestNav.append($prevButton, $nextButton, $navStatus);

        window.addEventListener('hashchange', function(event) {
            if(correspondenceIds.indexOf(window.location.hash.substr(1)) > -1) {
                event.preventDefault();
                updateUI();
            }
        });

        $(document).on('keydown', function(event) {
            if(event.which === 37) {
                event.preventDefault();
                prevCorrespondence();
            } else if(event.which === 39) {
                event.preventDefault();
                nextCorrespondence();
            } 
        })

    });


})(window.jQuery);