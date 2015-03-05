/* -*- coding: utf-8 -*- */
/* global cforum */

cforum.cf_messages = {
  initMarkdown: function(elem_id) {
    var elem = $("#" + elem_id);

    if(elem.length) {
      elem.markdown({autofocus: false, savable: false, iconlibrary: 'fa',
                     language: 'de', hiddenButtons: 'cmdPreview',
                     disabledButtons: 'cmdPreview',
                     additionalButtons: [
                       {
                         name: 'groupCustom',
                         data: [
                           cforum.markdown_buttons.hellip,
                           cforum.markdown_buttons.mdash,
                           cforum.markdown_buttons.almostEqualTo,
                           cforum.markdown_buttons.unequal,
                           cforum.markdown_buttons.times,
                           cforum.markdown_buttons.arrowRight,
                           cforum.markdown_buttons.arrowUp,
                           cforum.markdown_buttons.blackUpPointingTriangle,
                           cforum.markdown_buttons.rightwardsDoubleArrow,
                           cforum.markdown_buttons.trademark,
                           cforum.markdown_buttons.doublePunctuationMarks,
                           cforum.markdown_buttons.singlePunctuationMarks
                         ]
                       }
                     ]});
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
