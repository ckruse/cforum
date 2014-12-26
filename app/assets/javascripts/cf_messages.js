/* -*- coding: utf-8 -*- */
/* global cforum */

cforum.cf_messages = {
  init: function() {
    cforum.tags.initTags();
    cforum.cf_messages.initCursor();
  },

  initCursor: function() {
    var content = $("#cf_message_content");
    var subj = $("#cf_message_subject");
    var author = $("#cf_message_author");

    cforum.cf_threads.setCursor(author, subj, content);
  }
};

/* eof */
