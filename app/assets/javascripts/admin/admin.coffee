jQuery ->
  $('.locales a:first').tab('show')
  $('.accordion-body').on('hidden', ->
    $(@).prev().find('i').first().removeClass().addClass('icon-chevron-right')
  )
  $('.accordion-body').on('shown', ->
    $(@).prev().find('i').first().removeClass().addClass('icon-chevron-down'))
  $('.toggle-hidden').on('click', ->
    $(@).parents('td').find('div:hidden').show()
    false)
  $('#request_hidden_user_explanation_reasons').on('click', 'input', ->
    $('#request_hidden_user_subject, #request_hidden_user_explanation, #request_hide_button').show()
    info_request_id = $('#hide_request_form').attr('data-info-request-id')
    reason = $(this).val()
    $('#request_hidden_user_explanation_field').val("[loading default text...]")
    $.ajax "/hidden_user_explanation?reason=" + reason + "&info_request_id=" + info_request_id,
      type: "GET"
      dataType: "text"
      error: (data, textStatus, jqXHR) ->
        $('#request_hidden_user_explanation_field').val("Error: #{textStatus}")
      success: (data, textStatus, jqXHR) ->
        $('#request_hidden_user_explanation_field').val(data)
  )
  $('#incoming_messages').on('change', 'input[class=delete-checkbox]', ->
    selected = if $('#ids').val() isnt ""
      $('#ids').val().split(',')
    else
      []
    if this.checked
      selected.push this.value
      $('#ids').val(selected.join(','))
      $('input[value="Delete selected messages"]').attr("disabled", false)
    else
      selected = selected.filter (e) => e isnt this.value
      $('#ids').val(selected.join(','))
      if $('#ids').val() == ""
        $('input[value="Delete selected messages"]').attr("disabled", true)
  )
  $('#info_request_described_state').on('change', ->
    submit_button = $(this).closest('form').find(':submit')
    if (this.value is 'vexatious' or
        this.value is 'not_foi') and
       ($('#info_request_prominence').val() is 'normal' or
        $('#info_request_prominence').val() is 'backpage')
      $('#info_request_prominence').
        attr('title',
             'The request will not be hidden unless you change the prominence.')
      $('#info_request_prominence').tooltip('show')
      submit_button.
        attr('title',
             'Warning! You are about to save this request without hiding it!')
      submit_button.tooltip()
      submit_button.
        data('confirm',
             'You have set this request to "' + this.value + '" but not' +
             ' hidden it using prominence. Are you sure you want to continue?')
    else
      $('#info_request_prominence').removeAttr('title')
      $('#info_request_prominence').tooltip('destroy')
      submit_button.removeData('confirm')
      submit_button.removeAttr('title')
      submit_button.tooltip('destroy')
  )
  $('#info_request_prominence').on('change', ->
    submit_button = $(this).closest('form').find(':submit')
    if (this.value is 'normal' or this.value is 'backpage') and
       ($('#info_request_described_state').val() is 'not_foi' or
        $('#info_request_described_state').val() is 'vexatious')
      $(this).
        attr('title',
             'The request will not be hidden unless you change the prominence.')
      $(this).tooltip('show')
      submit_button.
        attr('title',
             'Warning! You are about to save this request without hiding it!')
      submit_button.tooltip()
      submit_button.
        data('confirm',
             'You have set this request to "' + this.value + '" but not' +
             ' hidden it using prominence. Are you sure you want to continue?')
    else
      $(this).removeAttr('title')
      $(this).tooltip('destroy')
      submit_button.removeAttr('title')
      submit_button.tooltip('destroy')
      submit_button.removeData('confirm')
  )
  $('[data-dismiss]').on 'click', ->
    console.log 'click'
    parent = $(this).parents(".#{$(this).data('dismiss')}")
    parent.hide('slow')

