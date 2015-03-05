/* -*- coding: utf-8 -*- */
/* global cforum */

cforum.cf_messages = {
  initMarkdown: function(elem_id) {
    var elem = $("#" + elem_id);

    if(elem.length) {
      elem.markdown({autofocus: false, savable: false, iconlibrary: 'fa',
                     language: 'de', hiddenButtons: 'cmdPreview',
                     disabledButtons: 'cmdPreview'});
    }
  },

  init: function() {
    cforum.tags.initTags();
    cforum.cf_messages.initCursor();

    cforum.cf_messages.initMarkdown("message_input");
  },

  initCursor: function() {
    var content = $("#message_input");
    var subj = $("#cf_message_subject");
    var author = $("#cf_message_author");

    cforum.cf_threads.setCursor(author, subj, content);
  }
};

/* eof */
