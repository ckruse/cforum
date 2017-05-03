/* -*- coding: utf-8 -*- */
/* global cforum:true, uconf, ActionCable */

(function(app) {
  var received = function(data) {
    cforum.events.trigger('message:' + data.type, data);
  };

  var createSub = function(forumSlug) {
    app.cable.subscriptions.create({ channel: 'MessageChannel', forum: forumSlug },
                                   { connected: app.common.connected,
                                     disconnected: app.common.disconnected,
                                     received: received });
  };

  app.events.on('cable:create', function() {
    var forums = app.currentForum ? [app.currentForum] : app.userForums;

    if(forums) {
      for(var i = 0; i < forums.length; ++i) {
        createSub(forums[i].slug);
      }
    }
  });
})(cforum);


/* eof */
