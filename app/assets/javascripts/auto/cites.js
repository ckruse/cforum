/* -*- coding: utf-8 -*- */
/* global cforum */

cforum.cites = {
  new: function() {
    $('#cite_url').on('change', function() {
      var val = $(this).val();

      if(val.substr(0, cforum.baseUrl.length) == cforum.baseUrl) {
        $('#cite_author').closest('.cf-cgroup').fadeOut('fast');
        $('#cite_cite').focus();
      }
      else {
        $('#cite_author').closest('.cf-cgroup').fadeIn('fast');
      }
    });

    cforum.messages.initPreview("cite_cite");
  }
};

/* eof */
