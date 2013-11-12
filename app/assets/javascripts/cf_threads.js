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
    var path = '/threads/' + (cforum.currentForum ? cforum.currentForum.slug : 'all');
    cforum.client.subscribe(path, cforum.cf_threads.newThreadArriving);

    path = '/messages/' + (cforum.currentForum ? cforum.currentForum.slug : 'all');
    cforum.client.subscribe(path, cforum.cf_threads.newMessageArriving);

  },

  newThreadArriving: function(message) {
    $.get(
      cforum.baseUrl + (cforum.currentForum ? cforum.currentForum.slug : '/all') + '/' + message.thread.thread_id,
      function(data) {
        $("body [data-js=threadlist]").prepend(data);
        $("#t" + message.thread.thread_id).addClass('new');
      }
    );
  },

  newMessageArriving: function(message) {
    $.get(
      cforum.baseUrl + (cforum.currentForum ? cforum.currentForum.slug : '/all') + '/' + message.thread.thread_id + '/' + message.message.message_id,
      function(data) {
        var $msg = $("#m" + message.message.parent_id);
        var $ol = $msg.next();

        if($ol.length === 0 || $ol[0].nodeName != 'OL') {
          $msg.after("<ol>");
          $ol = $msg.next();
        }
        console.log($ol);
        $ol.append("<li>" + data + "</li>");
        $("#m" + message.message.message_id).addClass("new");
      }
    );
  }

};

/* eof */
