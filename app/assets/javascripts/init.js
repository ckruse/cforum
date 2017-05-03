//= require action_cable
//= require_self
//= require_tree ./channels
/* -*- coding: utf-8 -*- */
/* global cforum:true, uconf, ActionCable */

cforum = {
  events: $({}),
  subscriptions: {},

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
        if(!pieces[i]) {
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
      var isSupported = (("WebSocket" in window && window.WebSocket !== undefined) ||
                         ("MozWebSocket" in window));

      cforum.client = {
        on: function() {},
        subscribe: function() {}
      };

      if(uconf('use_javascript_notifications') != 'no' && isSupported) {
        cforum.cable = ActionCable.createConsumer();
        cforum.events.trigger('cable:create');
      }

      var mql = window.matchMedia("only screen and (min-width: 35em)");
      if(!mql.matches && !document.location.hash) {
        window.scrollTo(0, $("main").offset().top);
      }
    },

    connected: function() {
      $("#username").addClass('connected');
    },
    disconnected: function() {
      $("#username").removeClass('connected');
    }
  }
};

$(document).ready(cforum.utils.init);

/* eof */
