/* -*- coding: utf-8 -*- */
/* global cforum, t */

cforum.cf_forums = {
  statsValues: null,
  stats: function() {
    Highcharts.setOptions({
      lang: t('highcharts')
    });

    $(".chart").highcharts({
      chart: { type: 'line' },
      title: null,
      xAxis: {
        categories: $.map(cforum.cf_forums.statsValues, function(val, i) { return Highcharts.dateFormat("%B %Y", new Date(val.moment)); })
      },
      yAxis: {
        title: { text: t('highcharts.threads') }
      },
      series: [{
        name: t('highcharts.threads'),
        data: $.map(cforum.cf_forums.statsValues, function(val, i) { return val.threads; })
      },
      {
        name: t('highcharts.messages'),
        data: $.map(cforum.cf_forums.statsValues, function(val, i) { return val.messages; })
      }]
    });
  }
};

/* eof */
