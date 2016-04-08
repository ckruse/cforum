/* -*- coding: utf-8 -*- */
/* global cforum */

if(!cforum.admin) {
  cforum.admin = {};
}

cforum.admin.groups = {
  init: function() {
    $("#forums-container").autolist({
      rowSelector: "[data-js=row]",
      deletionSelector: "[data-js=delete]"
    });
  }
};

// eof
