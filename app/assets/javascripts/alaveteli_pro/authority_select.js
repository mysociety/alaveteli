//= require alaveteli_pro/selectize
//= require alaveteli_pro/selectize.no_results

(function($){
  $(function(){
    var $select = $('.js-authority-select');
    var $form = $select.parents('form');
    var $publicBodyId = $('.js-public-body-id');
    var $publicBodyNotes = $('.js-public-body-notes');
    var $message = $('.js-outgoing-message-body');
    var searchUrl = $select.data('search-url');
    var initialOptions = [];
    var initialAuthority;
    if($select.data('initial-authority')) {
      initialAuthority = $select.data('initial-authority');
      initialOptions = [initialAuthority];
      // Selectize looks for values from the value field (id in this case) to
      // see if it should show something selected, but the html currently has
      // the name, not the id.
      $select.val(initialAuthority.id);
    }
    var defaultAuthorityName = $message.data('salutation-body-name');
    var salutationTemplate = $message.data('salutation-template');

    var currentAuthorityName = defaultAuthorityName;
    if (initialAuthority) {
      currentAuthorityName = initialAuthority.name;
    }

    var updateSalutation = function updateSalutation($item) {
      var oldAuthorityName = currentAuthorityName;
      var oldSalutation = salutationTemplate.replace(defaultAuthorityName, oldAuthorityName);
      var oldMessage = $message.val();

      // The selected item contains the name of the authority and the remove
      // button (which is a link), so this gets only the text node from the
      // DOM, ignoring the remove button. A naive .text() would return the
      // multiplication symbol in that button too.
      var newAuthorityName = $item.find('.item').contents().filter(function(){
        return this.nodeType === Node.TEXT_NODE;
      })[0].nodeValue;
      var newSalutation = salutationTemplate.replace(defaultAuthorityName, newAuthorityName);
      var newMessage = oldMessage.replace(oldSalutation, newSalutation);

      $message.val(newMessage);
      currentAuthorityName = newAuthorityName;
    };

    var updatePublicBodyIdField = function updatePublicBodyIdField(id) {
      $publicBodyId.val(id);
    };

    var updatePublicBodyNotes = function updatePublicBodyNotes(value) {
      var option = $selectizeInstance.options[value];
      if (option.notes && option.notes !== '') {
        $publicBodyNotes.html(
          '<h3>' + option.about + '</h3>' +
          '<p>' + option.notes + '</p>'
        );
        $publicBodyNotes.show();
      }
    };

    var hidePublicBodyNotes = function hidePublicBodyNotes() {
      $publicBodyNotes.hide();
    }

    var $selectize = $select.selectize({
      valueField: 'id',
      labelField: 'name',
      searchField: ['name', 'notes', 'short_name'],
      sortField: ['weight'],
      options: initialOptions,
      create: false,
      maxItems: 1,
      openOnFocus: false,
      render: {
        option: function(body, escape) { return body.html; }
      },
      onItemAdd: function(value, $item) {
        updateSalutation($item);
        updatePublicBodyIdField(value);
        updatePublicBodyNotes(value);
      },
      onChange: function(value) {
        if (value !== '') { return }
        hidePublicBodyNotes()
      },
      load: function(query, callback) {
        if (!query.length) return callback();
        $.getJSON(
          searchUrl,
          { query: encodeURIComponent(query) },
          function (data) {
            callback(data)
            $selectizeInstance.trigger('type')
          }
        ).fail(callback)
      },
      plugins: {
        remove_button: {},
        no_results: { message: $select.data('no-results') }
      }
    });
    if ($selectize[0]) var $selectizeInstance = $selectize[0].selectize;

    $form.on('submit', function(e) { e.preventDefault(); });
  });
})(window.jQuery);
