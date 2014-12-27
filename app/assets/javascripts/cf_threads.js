/* -*- coding: utf-8 -*- */
/* global cforum, Mustache, t */

cforum.cf_threads = {
  numThreads: 0,
  numMessages: 0,

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

  showNewAlert: function() {
    var alert = $("#new_messages_arrived");
    var append = false;

    if(!alert.length) {
      alert = $("<div class=\"cf-success\" id=\"new_messages_arrived\"></div>");
      append = true;
    }

    alert.text(Mustache.render(
      t('messages_threads'),
      {threads: cforum.cf_threads.numThreads,
       messages: cforum.cf_threads.numMessages}));

    if(append) {
      $("#alerts-container").append(alert);
    }
  },

  newThreadArriving: function(message) {
    cforum.cf_threads.numThreads += 1;
    cforum.cf_threads.numMessages += 1;
    cforum.cf_threads.showNewAlert();
  },

  newMessageArriving: function(message) {
    cforum.cf_threads.numMessages += 1;
    cforum.cf_threads.showNewAlert();
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
