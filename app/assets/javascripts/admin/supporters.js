$(document).ready(function() {
  $('#supporters_delete_prompt').hide();
  $('#supporters_unsubscribe_prompt').hide();
  $('#supporters_subscribe_prompt').hide();
  $('#supporters_action_form [name="unsubscribe"]').click(Supporters.unsubscribePrompt);
  $('#supporters_action_form [name="subscribe"]').click(Supporters.subscribePrompt);
  $('#supporters_action_form [name="delete"]').click(Supporters.deletePrompt);
});

window.Supporters = {
  deletePrompt: function() {
    Supporters.doPrompt('delete', Supporters.deleteAction);
  },

  unsubscribePrompt: function() {
    Supporters.doPrompt('unsubscribe', Supporters.unsubscribeAction);
  },

  subscribePrompt: function() {
    Supporters.doPrompt('subscribe', Supporters.subscribeAction);
  },

  doPrompt: function(name, action) {
    var prompt = $('#supporters_'+name+'_prompt');
    var button = $('#supporters_action_form [name="'+name+'"]');
    prompt.dialog({
      modal: true,
      buttons: [
        { text: "Ok",
          click: function() {
            action(button.attr('data-url'));
            return true;
          }
        },
        { text: "Cancel",
          click: function() {
            $(this).dialog("close");
            return false;
          }
        }]
    })
  },

  deleteAction: function(url) {
    Supporters.submitAction(url, 'delete');
  },

  unsubscribeAction: function(url) {
    Supporters.submitAction(url, 'unsubscribe');
  },

  subscribeAction: function(url) {
    Supporters.submitAction(url, 'subscribe');
  },

  getFormData: function() {
    var form = $('#supporters_action_form');
    return {
      first_name: form.find('input[name="first_name"]').val(),
      last_name: form.find('input[name="last_name"]').val(),
      email_address: form.find('input[name="email_address"]').val(),
      page_name: form.find('input[name="page_name"]').val()
    }
  },

  submitAction: function(url, operation) {
    $.get(url,
          $.extend({operation: operation}, Supporters.getFormData())
    ).then(function(data) {
      document.location.reload();
    }).fail(function() {
      alert("Something went wrong")
    });
  }
};
