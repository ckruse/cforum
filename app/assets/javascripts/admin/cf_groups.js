/* -*- coding: utf-8 -*- */
/* global cforum */

if(!cforum.admin) {
  cforum.admin = {};
}

cforum.admin.cf_groups = {
  init: function() {
    $("#forums-container").autolist({
      rowSelector: "[data-js=row]",
      deletionSelector: "[data-js=delete]"
    });
  }
};

// eof
