(function($) {
  $(function () {
    $('.correspondence .attachments').each(function() {
      var limit = 3;
      var link_collapsed_text = 'Show all attachments';
      var link_expanded_text = 'Show fewer attachments';

      var all_attachments = $(this).find('.list-of-attachments > .attachment');
      var over_limit_attachments = all_attachments.slice(limit);
      var show_more = $(this).find('.attachments__show-more');

      if (over_limit_attachments.length > 0) {
        over_limit_attachments.hide();
        show_more.text(link_collapsed_text);
        show_more.show();
      }

      show_more.click(function() {
        over_limit_attachments.slideToggle('fast');

        if ($(this).html() == link_collapsed_text) {
          $(this).html(link_expanded_text);
        }
        else {
          $(this).html(link_collapsed_text);
        }

        return false;
      });
    });
  });
})(window.jQuery);
