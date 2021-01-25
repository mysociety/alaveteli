(function($) {

  var filterSnippets = function($snippets, $filter) {
    var val = $filter.val();

    if ( val === 'all' ) {
      $snippets.attr('aria-hidden', null);
    } else {
      $snippets.attr('aria-hidden', function(){
        if ( $(this).attr('data-tags') && $(this).attr('data-tags').indexOf(val) > -1 ) {
          return null;
        } else {
          return "hidden";
        }
      });
    }
  };

  $(".js-snippet-library").each(function(){
    var $snippets = $(this).find('.snippet');
    var $filter = $(this).find('.snippet-library__filters select');

    filterSnippets( $snippets, $filter );

    $filter.on('change', function(e){
      filterSnippets( $snippets, $filter );
    });
  });

  var clipboard = new ClipboardJS('[data-clipboard-text]');

  clipboard.on('success', function(e) {
    var $btn = $(e.trigger);
    if ( e.action === 'copy' && $btn.attr('data-clipboard-success') ) {
      var btnOriginalHTML = $btn.html();
      $btn.html( $btn.attr('data-clipboard-success') );
      setTimeout(function(){
        $btn.html( btnOriginalHTML );
      }, 3000);
    }
    e.clearSelection();
  });

})(window.jQuery);
