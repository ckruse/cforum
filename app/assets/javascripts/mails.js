/* -*- coding: utf-8 -*- */
/* global cforum */

cforum.mails = {
  index: function() {
    $("#check-all-box").on('change', function() {

      if($(this).is(":checked")) {
        $(".mid-checkbox").attr("checked","checked");
      }
      else {
        $(".mid-checkbox").removeAttr('checked');
      }

    });
  },

  init: function() {
    cforum.cf_messages.initMarkdown("cf_priv_message_body");
  }
};

/* eof */
