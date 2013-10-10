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
  }
};

/* eof */
