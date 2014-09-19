$(function() {
  var endpoints = { 'heading' : '/admin/category_heading/reorder',
                    'category' : '/admin/category/reorder' }
  $('.save-order').each(function(index){

    // identify the elements that will work together
    var save_button = $(this);
    var save_notice = save_button.next();
    var save_panel = save_button.parent();
    var list_type = save_button.data('list-type');
    var list_element = $(save_button.data('list-id'));

    // on the first list change, show that there are unsaved changes
    list_element.sortable({
        update: function (event, ui) {
          if (save_button.is('.disabled')){
            save_button.removeClass("disabled");
            save_notice.html(save_notice.data('unsaved-text'));
            save_panel.effect('highlight', {}, 2000);
          }
        }
    });
    // on save, POST to endpoint
    save_button.click(function(){
      if (!save_button.is('.disabled')){
        var data = list_element.sortable('serialize', {'attribute': 'data-id'});
        var endpoint = endpoints[list_type];
        if (list_type == 'category'){
          heading_id = save_button.data('heading-id');
          endpoint = endpoint + "/" + heading_id;
        }
        var update_call = $.ajax({ data: data, type: 'POST', url: endpoint });

        // on success, disable the save button again, and show success notice
        update_call.done(function(msg) {
          save_button.addClass('disabled');
          save_panel.effect('highlight', {}, 2000);
          save_notice.html(save_notice.data('success-text'));
        })
        // on failure, show error message
        update_call.fail(function(jqXHR, msg) {
          save_panel.effect('highlight', {'color': '#cc0000'}, 2000);
          save_notice.html(save_notice.data('error-text') + jqXHR.responseText);
        });
      }
      return false;
    })
  });
});
