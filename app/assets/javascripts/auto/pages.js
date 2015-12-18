/* -*- coding: utf-8 -*- */

cforum.pages = {
  helpCites: null,
  help: function() {
    $(".chart-cites.chart").highcharts({
      chart: { type: 'spline' },
      title: null,
      xAxis: {
        categories: $.map(cforum.pages.helpCites,
                          function(val, i) {
                            return Highcharts.dateFormat("%B %Y",
                                                         new Date(val.created_at));
                          })
      },
      yAxis: { title: { text: t('highcharts.cnt_cites') } },
      series: [{
        name: t('highcharts.cites'),
        data: $.map(cforum.pages.helpCites, function(val, i) { return val.cnt; })
      }]
    });
  }
};

/* eof */
