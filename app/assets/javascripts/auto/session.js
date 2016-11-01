/* -*- coding: utf-8 -*- */
/* global cforum, t */

cforum.devise = {
  sessions: {
    init: function() {
      $(".show-password").on("click", function() {
        var field = $(".login-password");
        var type = field.attr("type");

        type = (type == 'text') ? 'password' : 'text';
        field.attr("type", type);
      });
      $(".show-password").css({display: 'inline'});
    }
  }
};

/* eof */
