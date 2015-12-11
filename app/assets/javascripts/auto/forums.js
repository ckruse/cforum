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
      yAxis: [
        { title: { text: t('highcharts.cnt_threads') } },
        { title: { text: t('highcharts.cnt_messages') }, opposite: true }],
      series: [{
        name: t('highcharts.threads'),
        data: $.map(cforum.cf_forums.statsValues, function(val, i) { return val.threads; }),
        yAxis: 0
      },
      {
        name: t('highcharts.messages'),
        data: $.map(cforum.cf_forums.statsValues, function(val, i) { return val.messages; }),
        yAxis: 1
      }]
    });

    var lastYear = moment().subtract(13, 'months').startOf('month');

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
      yAxis: [
        { title: { text: t('highcharts.cnt_threads') } },
        { title: { text: t('highcharts.cnt_messages') }, opposite: true }],
      series: [{
        name: t('highcharts.threads'),
        data: $.map(yearValues, function(val, i) { return val.threads; }),
        yAxis: 0
      },
      {
        name: t('highcharts.messages'),
        data: $.map(yearValues, function(val, i) { return val.messages; }),
        yAxis: 1
      }]
    });

    $(".chart-users-year.chart").highcharts({
      chart: { type: 'line' },
      title: null,
      xAxis: {
        categories: $.map(yearValues, function(val, i) { return Highcharts.dateFormat("%B %Y", new Date(val.moment)); })
      },
      yAxis: {
        title: { text: t('highcharts.cnt') }
      },
      series: [{
        name: t('highcharts.users'),
        data: $.map(yearValues, function(val, i) { return val.users; })
      }]
    });
  }
};

/* eof */
