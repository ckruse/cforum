/* -*- coding: utf-8 -*- */
/* global cforum */

cforum.cites = {
  new: function() {
    $('#cf_cite_url').on('change', function() {
      var val = $(this).val();

      if(val.substr(0, cforum.baseUrl.length) == cforum.baseUrl) {
        $('#cf_cite_author').closest('.cf-cgroup').fadeOut('fast');
        $('#cf_cite_cite').focus();
      }
      else {
        $('#cf_cite_author').closest('.cf-cgroup').fadeIn('fast');
      }
    });
  }
};

/* eof */
