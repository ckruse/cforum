/* -*- coding: utf-8 -*- */
/* global cforum:true, uconf, ActionCable */

(function(app) {
  app.events.on('cable:create', function() {
    var received = function(data) {
      cforum.events.trigger(data.type, data);
    };

    if(app.currentUser) {
      app.cable.subscriptions.create({ channel: 'UserChannel' },
                                     { connected: cforum.common.connected,
                                       disconnected: cforum.common.disconnected,
                                       received: received });
    }
  });
})(cforum);


/* eof */
