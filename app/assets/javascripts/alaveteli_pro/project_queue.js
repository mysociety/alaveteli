(function($){

    function handleQueueResponse(html) {
        var $newPage = $(html);
        var $newRequest = $newPage.find('.js-queue-request-wrapper');
        var $oldRequest = $('.js-queue-request-wrapper');
        if ($newRequest.length) {

            $newRequest.addClass('incoming');
            $newRequest.insertAfter($oldRequest);
            $oldRequest.addClass('outgoing');
            
            setTimeout(function() {
                $newRequest.removeClass('incoming');
            }, 100);
           
            setTimeout(function() {
                $oldRequest.remove()
            }, 500);

            var $newForm = $newPage.find('.js-project-queue-form');
            var $oldForm = $('.js-project-queue-form');
            
            $oldForm.replaceWith($newForm);

            $('html, body').animate({scrollTop: 0}, 100);

        } else {
            //todo should we assume this is the right page to send them to?
            window.location = '../';
        }
        
    }

    function handleQueueFailure() {
        window.location.reload();
        //todo handle queue failures
    }

    $(document).on('submit', '.js-project-queue-form', function(e) {
        e.preventDefault();

        var $form = $(this);

        $.ajax({
            method: $form.attr('method'),
            url: $form.attr('action'),
            data: $form.serialize()
        }).done(
            handleQueueResponse
        ).fail(
            handleQueueFailure
        );

    });

    $(document).on('click', '.js-project-queue-skip-button', function(e) {
        e.preventDefault();

        $.ajax({
            method: 'get',
            url: $(this).attr('href')
        }).done(
            handleQueueResponse
        ).fail(
            handleQueueFailure
        );  
    });

})(window.jQuery);
