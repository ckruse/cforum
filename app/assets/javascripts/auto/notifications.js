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

  notifyNew: function(event, data) {
    cforum.notifications.updateNotifications(data, true);
  },

  notifyUpdate: function(event, data) {
    cforum.notifications.updateNotifications(data, false);
  },

  updateNotifications: function(data, updateFavicon) {
    var noti = $("#notifications-display");
    noti.addClass('new');

    noti.text(data.unread);

    var title = noti.attr('title');
    title = title.replace(/\d+/, data.unread);
    noti.parent().children().attr('title', title);

    cforum.events.trigger("update", data);
    cforum.events.trigger("update:notifications", data);

    noti.animate({'font-size': '1.3em'}, 200, function() {
      noti.animate({'font-size': '1em'}, 200);
    });

    if(updateFavicon) {
      cforum.updateFavicon();
    }
  }
};

$(function() {
  if(cforum.currentUser) {
    cforum.events.on('notification:create', cforum.notifications.notifyNew);
    cforum.events.on('notification:update', cforum.notifications.notifyUpdate);
  }
});

/* eof */
