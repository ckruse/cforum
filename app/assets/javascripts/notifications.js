/* -*- coding: utf-8 -*- */
/* global cforum */

cforum.notifications = {
  index: function() {
    $("#check-all-box").on('change', function() {

      if($(this).is(":checked")) {
        $(".nid-checkbox").attr("checked","checked");
      }
      else {
        $(".nid-checkbox").removeAttr('checked');
      }

    });
  },

  notifyNew: function(data) {
    var noti = $("#notifications-currentuser");
    var txt = noti.text();
    noti.addClass('new');

    if(txt) {
      txt = parseInt(txt);
      txt += 1;
      noti.text(txt);
    }

    noti.animate({'font-size': '1.3em'}, 200, function() {
      noti.animate({'font-size': '1em'}, 200);
    });
  }
};

$(function() {
  if(cforum.currentUser) {
    cforum.client.subscribe('/user/' + cforum.currentUser.user_id + "/notifications", cforum.notifications.notifyNew);
  }
});

/* eof */
