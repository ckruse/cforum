/* -*- coding: utf-8 -*- */
/* global cforum, Faye */

cforum = {
  utils: {
    exec: function(controller, action) {
      var ns = cforum;
      action = (action === undefined) ? "init" : action;

      if(controller.length > 0) {
        for(var i = 0; i < controller.length; ++i) {
          if(!ns[controller[i]]) {
            return;
          }

          ns = ns[controller[i]];
        }

        if(typeof ns[action] == "function") {
          ns[action]();
        }
      }
    },

    init: function() {
      var body = document.body, controller = body.getAttribute("data-controller"), action = body.getAttribute("data-action");

      var pieces = controller.split('/');
      controller = [];
      for(var i = 0; i < pieces.length; ++i) {
        if(pieces[i] == "") {
          continue;
        }

        controller.push(pieces[i]);
      }

      cforum.utils.exec(["common"]);
      cforum.utils.exec(controller);
      cforum.utils.exec(controller, action);
    }
  },

  common: {
    init: function() {
      if(uconf('use_javascript_notifications') != 'no') {
        cforum.client = io(cforum.wsUrl);

        cforum.client.on('connect', function() {
          if(cforum.currentUser) {
            cforum.client.emit("login", {user: cforum.currentUser.user_id, wstoken: cforum.websocketToken});
            $("#username").addClass('connected');
          }
        });

        cforum.client.on("disconnect", function() { $("#username").removeClass('connected'); });
      }
      else {
        cforum.client = {
          on: function() {},
          subscribe: function() {}
        };
      }
    }
  }
};

$(document).ready(cforum.utils.init);

/* eof */
