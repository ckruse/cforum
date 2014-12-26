/* -*- coding: utf-8 -*- */
/* global cforum */

cforum.cf_threads = {
  new: function() {
    cforum.tags.initTags();
    cforum.cf_threads.initCursor();
  },
  create: function() {
    cforum.tags.initTags();
    cforum.cf_threads.initCursor();
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

        $ol.append("<li>" + data + "</li>");
        $("#m" + message.message.message_id).addClass("new");
      }
    );
  },

  initCursor: function() {
    var content = $("#cf_thread_message_content");
    var subj = $("#cf_thread_message_subject");
    var author = $("#cf_thread_message_author");

    cforum.cf_threads.setCursor(author, subj, content);
  },

  setCursor: function(author, subject, content) {
    if(content.length > 0) {
      if(!subject.val()) {
        subject.focus();
      }
      else {
        if(cforum.currentUser) {
          content.focus();
          cforum.cf_threads.setCursorInContent(content);
        }
        else {
          if(!author.val()) {
            author.focus();
          }
          else {
            content.focus();
            cforum.cf_threads.setCursorInContent(content);
          }
        }
      }
    }
  },

  setCursorInContent: function(content) {
    var cnt = content.val();
    var i;

    for(i = 0; i < cnt.length; ++i) {
      if(cnt.substr(i, 1) == '>' &&
         (i === 0 || cnt.substr(i - 1, 1) == "\n") &&
         cnt.substr(i + 1, 1) == ' ') {
        content.setCursorPosition(i);
        return;
      }
    }
  }

};

/* eof */
