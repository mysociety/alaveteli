$(document).ready(function($) {
  var filterRequestCategories = function(){
    var filterValue = $('#request-category-filter-input').val().toLowerCase();
    if (filterValue.length <= 1) {
      $('.request-category').removeClass('hide').each(function() {
        removeMarks( $(this) );
      });
    } else {
      $('.request-category').each(function() {
        var $rc = $(this);

        if ($rc.text().toLowerCase().includes(filterValue)) {
          $rc.removeClass('hide');
          addMarks( $rc, filterValue );
        } else {
          $rc.addClass('hide');
          removeMarks( $rc );
        }
      });
    }
  };

  var removeMarks = function($el) {
    $el.find('mark').contents().unwrap();
  };

  var addMarks = function($el, text) {
    // Remove existing marks first!
    removeMarks($el);

    // Add marks inside h3 and a descendants.
    var regex = new RegExp('(' + text + ')', 'gi');
    $el.find('h3, a').each(function(){
      $(this).html(function(_, html){
        return html.replace(regex, '<mark>$1</mark>');
      });
    });
  };

  var $rcf = $('.request-category-filter');
  if ( $rcf.length ) {
    $rcf.removeClass('hide');
    $('#request-category-filter-input').val('').on('input', filterRequestCategories);
  }
});
