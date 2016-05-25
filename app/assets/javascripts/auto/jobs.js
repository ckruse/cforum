/* -*- coding: utf-8 -*- */
/* global cforum, Highcharts, t */

cforum.admin.jobs = {
  jobsCount: null,
  index: function() {
    Highcharts.setOptions({
      lang: t('highcharts')
    });

    $("#chart").highcharts({
      chart: { type: 'spline' },
      title: null,
      xAxis: {
        categories: $.map(cforum.admin.jobs.jobsCount,
                          function(val, i) {
                            return Highcharts.dateFormat("%A, %d. %B %Y",
                                                         new Date(val.day));
                          })
      },
      yAxis: { title: { text: t('highcharts.cnt_jobs') } },
      series: [{
        name: t('highcharts.jobs'),
        data: $.map(cforum.admin.jobs.jobsCount, function(val, i) { return val.cnt; })
      }]
    });
  }
};

/* eof */
