(function($){


    $('.js-request-navigation').each(function() {
        var $requestNav = $(this);
        var statusText = $(this).attr('data-status-text');
        var $allCorrespondence = $('.correspondence');

        var updateStatusText = function updateStatusText() {
            $navStatus.text(
                statusText.replace('[[x]]', 1).replace('[[y]]', $allCorrespondence.length)
            );
        }

        var $navStatus = $('<p>');
        updateStatusText();

        $requestNav.append($navStatus);


    });


})(window.jQuery);