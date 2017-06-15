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

