/* -*- coding: utf-8 -*- */
/* global cforum, t */

cforum.devise = {
  sessions: {
    init: function() {
      $(".login-password").after(
        '<button class="show-password" type="button" title="' +
          t("show_password") +
          '"></button>'
      );
      $(".show-password").on("click", function(ev) {
        ev.preventDefault();

        var field = $(".login-password");
        var type = field.attr("type");

        type = type == "text" ? "password" : "text";
        field.attr("type", type);
      });
      //$(".show-password").css({display: 'inline'});
    }
  }
};

/* eof */
