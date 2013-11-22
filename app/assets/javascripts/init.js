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
      if(typeof Faye !== 'undefined') {
        cforum.client = new Faye.Client(cforum.fayeUrl, {timeout: 120, retry: 5});

        cforum.client.on('transport:up', function() { $(".cf-right-nav .username").addClass('connected'); });
        cforum.client.on('transport:down', function() { $(".cf-right-nav .username").removeClass('connected'); });
      }
    }
  }
};

$(document).ready(cforum.utils.init);

/* eof */
