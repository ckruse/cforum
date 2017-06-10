/* -*- coding: utf-8 -*- */
/* global cforum, t, moment, Highcharts */

cforum.forums = {
  statsValues: null,
  usersTwelveMonths: null,

  stats: function() {
    Highcharts.setOptions({
      lang: t('highcharts')
    });

    $(".chart-all.chart").highcharts({
      chart: { type: 'line' },
      title: null,
      xAxis: {
        categories: $.map(cforum.forums.statsValues, function(val, i) { return Highcharts.dateFormat("%B %Y", new Date(val.moment)); })
      },
      yAxis: [
        { title: { text: t('highcharts.cnt_threads') } },
        { title: { text: t('highcharts.cnt_messages') }, opposite: true }],
      series: [{
        name: t('highcharts.threads'),
        data: $.map(cforum.forums.statsValues, function(val, i) { return val.threads; }),
        yAxis: 0
      },
      {
        name: t('highcharts.messages'),
        data: $.map(cforum.forums.statsValues, function(val, i) { return val.messages; }),
        yAxis: 1
      }]
    });

    var lastYear = moment().subtract(13, 'months').startOf('month');

    var yearValues = $.grep(cforum.forums.statsValues, function(val, i) {
      var mmt = moment(val.moment);
      if(mmt.isBefore(lastYear)) {
        return false;
      }
      return true;
    });

    var lastFourYears = moment().subtract(48, 'months').startOf('month');

    var lastFourYearValues = $.grep(cforum.forums.statsValues, function(val, i) {
      var mmt = moment(val.moment);
      if(mmt.isBefore(lastFourYears)) {
        return false;
      }
      return true;
    });



    $(".chart-year.chart").highcharts({
      chart: { type: 'spline' },
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
      chart: { type: 'spline' },
      title: null,
      xAxis: {
        categories: $.map(cforum.forums.usersTwelveMonths,
                          function(val, i) { return Highcharts.dateFormat("%B %Y", new Date(val.moment)); })
      },
      yAxis: {
        title: { text: t('highcharts.cnt') }
      },
      series: [{
        name: t('highcharts.users'),
        data: $.map(cforum.forums.usersTwelveMonths, function(val, i) { return val.cnt; })
      }]
    });

    $(".chart-48-months.chart").highcharts({
      chart: { type: 'spline' },
      title: null,
      xAxis: {
        categories: $.map(lastFourYearValues, function(val, i) { return Highcharts.dateFormat("%B %Y", new Date(val.moment)); })
      },
      yAxis: [
        { title: { text: t('highcharts.cnt_threads') } },
        { title: { text: t('highcharts.cnt_messages') }, opposite: true }],
      series: [{
        name: t('highcharts.threads'),
        data: $.map(lastFourYearValues, function(val, i) { return val.threads; }),
        yAxis: 0
      },
      {
        name: t('highcharts.messages'),
        data: $.map(lastFourYearValues, function(val, i) { return val.messages; }),
        yAxis: 1
      }]
    });

  }
};

/* eof */
