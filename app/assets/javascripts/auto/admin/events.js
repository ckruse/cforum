/* -*- coding: utf-8 -*- */
/* global cforum */

if(!cforum.admin) {
  cforum.admin = {};
}

cforum.admin.events = {
  init: function() {
    cforum.messages.initPreview("event_description");
  }
};

/* eof */
