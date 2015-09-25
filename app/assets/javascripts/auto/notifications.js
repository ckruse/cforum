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
    var noti = $("#notifications-display");
    var txt = noti.text();
    noti.addClass('new');

    if(txt) {
      txt = parseInt(txt, 10);
      txt += 1;
      noti.text(txt);

      var title = noti.attr('title');
      title = title.replace(/\d+/, txt);
      noti.parent().children().attr('title', title);
    }

    noti.animate({'font-size': '1.3em'}, 200, function() {
      noti.animate({'font-size': '1em'}, 200);
    });

    cforum.updateFavicon();
  }
};

$(function() {
  if(cforum.currentUser) {
    cforum.client.on('notification:create', cforum.notifications.notifyNew);
  }
});

/* eof */
