(function($){


    $('.js-request-navigation').each(function() {
        var $requestNav = $(this);
        var statusText = $(this).attr('data-status-text');
        var $allCorrespondence = $('.correspondence');
        var currentCorrespondenceIndex = 0;
        var correspondenceIds = [];
        
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

        var $navStatus = $('<p>');
        updateStatusText();

        $requestNav.append($navStatus);

        window.addEventListener('hashchange', updateStatusText);

    });


})(window.jQuery);