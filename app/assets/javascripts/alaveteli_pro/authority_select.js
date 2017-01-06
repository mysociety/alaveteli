(function($){
  $(function(){
    var $select = $('.js-authority-select');
    var $message = $('.js-outgoing-message-body');
    var authorityName = '';
    $select.selectize({
      valueField: 'id',
      labelField: 'name',
      searchField: 'name',
      options: [],
      create: false,
      maxItems: 1,
      render: {
        option: function(body, escape) {
          // No need to use escape because data is trusted (from our DB)
          var html = '<div class="recipient-result">';
          html += '<h4 class="name">' + body.name + '</h4>';
          html += '<p class="description">' + body.notes + '</p>';
          html += '<p class="requests">' + body.info_requests_visible_count + ' requests made</p>';
          html += '</div>';
          return html;
        }
      },
      onChange: function(value) {
        var oldAuthorityName = authorityName;
        var oldSalutation = 'Dear ' + oldAuthorityName + ',';
        var oldMessage = $message.val();

        var newAuthorityName = $select.find('option:selected').text();
        var newSalutation = 'Dear ' + newAuthorityName + ',';
        var newMessage = oldMessage.replace(oldSalutation, newSalutation);

        $message.val(newMessage);
        authorityName = newAuthorityName;
      }
    });
  });
})(window.jQuery);
