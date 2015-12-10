/* -*- coding: utf-8 -*- */
/* global cforum, t, moment */

cforum.cf_forums = {
  statsValues: null,
  stats: function() {
    Highcharts.setOptions({
      lang: t('highcharts')
    });

    $(".chart-all.chart").highcharts({
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

    var now = moment();
    var lastYear = now.subtract(1, 'year').startOf('month');

    var yearValues = $.grep(cforum.cf_forums.statsValues, function(val, i) {
      var mmt = moment(val.moment);
      if(mmt.isBefore(lastYear)) {
        return false;
      }
      return true;
    });

    $(".chart-year.chart").highcharts({
      chart: { type: 'line' },
      title: null,
      xAxis: {
        categories: $.map(yearValues, function(val, i) { return Highcharts.dateFormat("%B %Y", new Date(val.moment)); })
      },
      yAxis: {
        title: { text: t('highcharts.threads') }
      },
      series: [{
        name: t('highcharts.threads'),
        data: $.map(yearValues, function(val, i) { return val.threads; })
      },
      {
        name: t('highcharts.messages'),
        data: $.map(yearValues, function(val, i) { return val.messages; })
      }]
    });
  }
};

/* eof */
