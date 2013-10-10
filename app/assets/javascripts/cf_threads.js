/* -*- coding: utf-8 -*- */
/* global cforum */

cforum.cf_threads = {
  new: function() {
    cforum.tags.initTags();
  },
  create: function() {
    cforum.tags.initTags();
  },

  index: function() {
    var path = '/messages/' + (cforum.currentForum ? cforum.currentForum.slug : 'all');
    cforum.client.subscribe(path, cforum.cf_threads.newMessageArriving);
  },

  newMessageArriving: function(message) {
    $.get(
      cforum.baseUrl + (cforum.currentForum ? cforum.currentForum.slug : '/all') + '/' + message.thread.thread_id,
      function(data) {
        if(message.type == 'thread') {
          $("body [data-js=threadlist]").prepend(data);
          $("#t" + message.thread.thread_id).addClass('new');
        }
        else {
          $("[data-js=thread-" + message.thread.thread_id + "]").replaceWith(data);
          $("#m" + message.message.message_id).addClass('new');
        }
      }
    );
  }

};

/* eof */
