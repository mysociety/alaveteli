(function($){


    $('.js-request-navigation').each(function() {
        var $requestNav = $(this); 
        var nextText = $(this).attr('data-next-text');
        var prevText = $(this).attr('data-prev-text');

        var scrollTo = function scrollTo($el) {
            $('html, body').animate({
                scrollTop: $el.offset().top
            }, 150);
        }

        var previousCorrespondence = function previousCorrespondence() {
            var $previousCorrespondence = getCurrentCorrespondence().prevAll('.correspondence').eq(0);
            if ($previousCorrespondence.length) {
                scrollTo($previousCorrespondence);
            }
        }

        var nextCorrespondence = function nextCorrespondence() {
            var $nextCorrespondence = getCurrentCorrespondence().nextAll('.correspondence').eq(0);
            if ($nextCorrespondence.length) {
                scrollTo($nextCorrespondence);
            }
        }

        var getCurrentCorrespondence = function getCurrentCorrespondence() {
            var current;
            $('.correspondence').each(function() {
                if(isThisElementVisible($(this))) {
                    current = $(this);
                    return false;
                }
            });
            return current;
        }

        //create two buttons
        var $prev = $('<button>').text(prevText).on('click', previousCorrespondence);
        var $next = $('<button>').text(nextText).on('click', nextCorrespondence);

        $requestNav.append($prev, $next);

        //TODO: Account for admin bar
        var isThisElementVisible = function isThisElementVisible($el) {
            return $el.offset().top + $el.outerHeight() >  $(window).scrollTop();
        }

        //assign click handlers
        
        

    });


})(window.jQuery);