/* -*- coding: utf-8 -*- */
/* global cforum, Highcharts, t */

cforum.admin.jobs = {
  jobsCount: null,
  index: function() {
    Highcharts.setOptions({
      lang: t('highcharts')
    });

    var keys = cforum.admin.jobs.jobsCount.sort(function(a,b) {
      var a_date = new Date(a.day);
      var b_date = new Date(b.day);
      return a_date.getTime() - b_date.getTime();
    });

    $("#chart").highcharts({
      chart: { type: 'spline' },
      title: null,
      xAxis: {
        categories: $.map(keys,
                          function(val, i) {
                            return Highcharts.dateFormat("%A, %d. %B %Y",
                                                         new Date(val.day));
                          })
      },
      yAxis: { title: { text: t('highcharts.cnt_jobs') } },
      series: [{
        name: t('highcharts.jobs'),
        data: $.map(keys, function(val, i) { return val.cnt; })
      }]
    });
  }
};

/* eof */
