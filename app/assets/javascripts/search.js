/* -*- coding: utf-8 -*- */
/* global cforum, t */

cforum.cf_search = {
  init: function() {
    var $explanation = $(".search-explanation");

    $explanation.css('display', 'none');
    $explanation.before('<small class="search-show-help">' + t('show_help') + "</small>");

    $(".search-show-help").on('click', function() {
      $(this).remove();
      $explanation.fadeIn('fast');
    });
  }
};

/* eof */
