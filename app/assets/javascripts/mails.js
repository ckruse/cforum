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
  },

  notifyNew: function(data) {
    var mails = $("#mails");
    var txt = mails.text();
    mails.addClass('new');

    if(txt) {
      txt = parseInt(txt, 10);
      txt += 1;
      mails.text(txt);

      var title = mails.attr('title');
      title = title.replace(/\d+/, txt);
      mails.parent().children().attr('title', title);
    }

    mails.animate({'font-size': '1.3em'}, 200, function() {
      mails.animate({'font-size': '1em'}, 200);
    });

    cforum.updateFavicon();
  }
};

$(function() {
  if(cforum.currentUser) {
    cforum.client.subscribe('/user/' + cforum.currentUser.user_id + "/mails", cforum.mails.notifyNew);
  }
});


/* eof */
