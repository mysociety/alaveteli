(($) ->
  $(document).ready(->
    $('.locales a:first').tab('show')
  )
  $('.toggle-hidden').live('click', ->
    $(@).parents('td').find('div:hidden').show()
    false
  )
)(jQuery)

