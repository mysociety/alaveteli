(function() {
  jQuery(function() {
    $('.locales a:first').tab('show');
    $('.accordion-body').on('hidden', function() {
      return $(this).prev().find('i').first().removeClass().addClass('icon-chevron-right');
    });
    $('.accordion-body').on('shown', function() {
      return $(this).prev().find('i').first().removeClass().addClass('icon-chevron-down');
    });
    $('.toggle-hidden').on('click', function() {
      $(this).parents('td').find('div:hidden').show();
      return false;
    });
    $('#request_hidden_user_explanation_reasons').on('click', 'input', function() {
      var info_request_id, message;
      $('#request_hidden_user_subject, #request_hidden_user_explanation, #request_hide_button').show();
      info_request_id = $('#hide_request_form').attr('data-info-request-id');
      message = $(this).attr('data-message');
      $('#request_hidden_user_explanation_field').val("[loading default text...]");
      return $.ajax("/hidden_user_explanation?message=" + message + "&info_request_id=" + info_request_id, {
        type: "GET",
        dataType: "text",
        error: function(data, textStatus, jqXHR) {
          return $('#request_hidden_user_explanation_field').val("Error: " + textStatus);
        },
        success: function(data, textStatus, jqXHR) {
          return $('#request_hidden_user_explanation_field').val(data);
        }
      });
    });
    $('#incoming_messages').on('change', 'input[class=delete-checkbox]', function() {
      var selected;
      selected = $('#ids').val() !== "" ? $('#ids').val().split(',') : [];
      if (this.checked) {
        selected.push(this.value);
        $('#ids').val(selected.join(','));
        return $('input[value="Delete selected messages"]').attr("disabled", false);
      } else {
        selected = selected.filter((function(_this) {
          return function(e) {
            return e !== _this.value;
          };
        })(this));
        $('#ids').val(selected.join(','));
        if ($('#ids').val() === "") {
          return $('input[value="Delete selected messages"]').attr("disabled", true);
        }
      }
    });
    $('#info_request_described_state').on('change', function() {
      var submit_button;
      submit_button = $(this).closest('form').find(':submit');
      if ((this.value === 'vexatious' || this.value === 'not_foi') && ($('#info_request_prominence').val() === 'normal' || $('#info_request_prominence').val() === 'backpage')) {
        $('#info_request_prominence').attr('title', 'The request will not be hidden unless you change the prominence.');
        $('#info_request_prominence').tooltip('show');
        submit_button.attr('title', 'Warning! You are about to save this request without hiding it!');
        submit_button.tooltip();
        return submit_button.data('confirm', 'You have set this request to "' + this.value + '" but not' + ' hidden it using prominence. Are you sure you want to continue?');
      } else {
        $('#info_request_prominence').removeAttr('title');
        $('#info_request_prominence').tooltip('destroy');
        submit_button.removeData('confirm');
        submit_button.removeAttr('title');
        return submit_button.tooltip('destroy');
      }
    });
    $('#info_request_prominence').on('change', function() {
      var submit_button;
      submit_button = $(this).closest('form').find(':submit');
      if ((this.value === 'normal' || this.value === 'backpage') && ($('#info_request_described_state').val() === 'not_foi' || $('#info_request_described_state').val() === 'vexatious')) {
        $(this).attr('title', 'The request will not be hidden unless you change the prominence.');
        $(this).tooltip('show');
        submit_button.attr('title', 'Warning! You are about to save this request without hiding it!');
        submit_button.tooltip();
        return submit_button.data('confirm', 'You have set this request to "' + this.value + '" but not' + ' hidden it using prominence. Are you sure you want to continue?');
      } else {
        $(this).removeAttr('title');
        $(this).tooltip('destroy');
        submit_button.removeAttr('title');
        submit_button.tooltip('destroy');
        return submit_button.removeData('confirm');
      }
    });
    return $('[data-dismiss]').on('click', function() {
      var parent;
      console.log('click');
      parent = $(this).parents("." + ($(this).data('dismiss')));
      return parent.hide('slow');
    });
  });

}).call(this);
