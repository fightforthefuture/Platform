$(document).ready(function() {
  $('#supporters_search_form').submit(Supporters.search)
  $('#supporters_delete_prompt').hide();
  $('#supporters_unsubscribe_prompt').hide();
  $('#supporters_subscribe_prompt').hide();
  $('.progressbar').hide();
  $('#supporters_action_form [name="unsubscribe"]').click(Supporters.unsubscribePrompt);
  $('#supporters_action_form [name="subscribe"]').click(Supporters.subscribePrompt);
  $('#supporters_action_form [name="delete"]').click(Supporters.deletePrompt);
});

window.Supporters = {
  actionUrl: function() {
    return $('#supporters_action_url').attr('data-url');
  },

  pollUrl: function() {
    return $('#supporters_poll_url').attr('data-url');
  },

  viewUrl: function(jobId) {
    return $('#supporters_view_url').attr('data-url') + "?job_id=" + jobId;
  },

  actionForm: function() {
    return $('#supporters_action_form');
  },


  searchPrompt: function() {
    var prompt = $('#supporters_search_prompt');
    prompt.dialog({modal: true});
    Supporters.progressBar(prompt);
  },

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
        { text: "Cancel",
          click: function() {
            $(this).dialog("close");
            return false;
          }
        },
        { text: "Ok",
          click: function() {
            Supporters.progressBar(prompt);
            action(Supporters.actionUrl());
            return true;
          }
        }
      ]
    })
  },


  // A "fake" progress bar that increments from 0 to 100 over
  // 100s. This should be enough for most queries to finish.
  progressBar: function(prompt) {
    var progressbar = prompt.find('.progressbar');
    var value = 0;
    progressbar.progressbar({value: value}).show();
    var timeoutId = null;
    var inc = function() {
      value++;
      if(value <= 100) {
        progressbar.progressbar("option", "value", value)
      } else {
        window.clearTimeout(timeoutId);
      }
    };
    timeoutId = window.setInterval(inc, 1000);
    return progressbar;
  },

  search: function(evt) {
    console.log('search', 'start');
    evt.preventDefault();
    Supporters.searchPrompt();
    var form = $('#supporters_search_form');
    Supporters.searchAction(form);
    return false;
  },


  searchAction: function(form) {
    var url = Supporters.actionUrl();
    var formData = Supporters.getFormData(form);
    return Supporters.submitAction(url, 'query', formData)
      .then(Supporters.pollUntilDone)
      .then(Supporters.redirectToView);
  },

  deleteAction: function(url) {
    Supporters.submitAction(url, 'delete', Supporters.getActionFormData())
      .then(Supporters.pollUntilDone)
      .then(Supporters.searchAction(Supporters.actionForm()));
  },

  unsubscribeAction: function(url) {
    Supporters.submitAction(url, 'unsubscribe', Supporters.getActionFormData())
      .then(Supporters.pollUntilDone)
      .then(Supporters.searchAction(Supporters.actionForm()));
  },

  subscribeAction: function(url) {
    Supporters.submitAction(url, 'subscribe', Supporters.getActionFormData())
      .then(Supporters.pollUntilDone)
      .then(Supporters.searchAction(Supporters.actionForm()));
  },


  getActionFormData: function() {
    return Supporters.getFormData(Supporters.actionForm());
  },

  getFormData: function(form) {
    return {
      first_name: form.find('input[name="first_name"]').val(),
      last_name: form.find('input[name="last_name"]').val(),
      email_address: form.find('input[name="email_address"]').val(),
      page_name: form.find('input[name="page_name"]').val()
    }
  },


  submitAction: function(url, operation, formData) {
    var promise = $.get(url,
          $.extend({operation: operation}, formData)
    ).then(function(data) {
      console.log('submitAction', data, data['data']['job_id']);
      var jobId = data['data']['job_id'];
      console.log('submitAction', jobId);
      return jobId;
    });
    return promise;
  },

  pollUntilDone: function(jobId) {
    console.log('pollUntilDone', jobId);
    var url = Supporters.pollUrl();
    var timeoutId = null;
    var deferred = jQuery.Deferred();

    var check = function() {
      $.get(url, {job_id: jobId}).done(function(json) {
        if(json['data']['success']) {
          if(json['data']['complete']) {
            window.clearTimeout(timeoutId);
            deferred.resolve(jobId);
         } else {
            // Wait again
          }
        } else {
          window.clearTimeout(timeoutId);
          deferred.reject(jobId);
        }

      })
    }
    timeoutId = window.setInterval(check, 5000);
    return deferred;
  },

  redirectToView: function(jobId) {
    console.log('redirectToView', jobId);
    var url = Supporters.viewUrl(jobId);
    window.location = url;
  }

};
