/* -*- coding: utf-8 -*- */
/* global cforum, t, Highcharts, moment */

cforum.users = {
  messagesByMonths: null,

  show: function() {
    Highcharts.setOptions({
      lang: t('highcharts')
    });

    var dateAsKeys = {};
    var min, max, d, v;

    for(var i = 0; i < cforum.users.messagesByMonths.length; ++i) {
      v = cforum.users.messagesByMonths[i];
      d = moment(v.created_at);

      if(!min || d.isBefore(min)) {
        min = moment(v.created_at);
      }

      if(!max || d.isAfter(max)) {
        max = moment(v.created_at);
      }

      dateAsKeys[d.year() + "-" + d.month()] = v.cnt;
    }

    var keys = [];
    for(d = moment(min); d.isSameOrBefore(max); d = d.add(1, 'months')) {
      var curKey = d.year() + "-" + d.month();
      keys.push(moment(d));

      if(!dateAsKeys[curKey]) {
        dateAsKeys[curKey] = 0;
      }
    }

    $("#user-activity-stats").highcharts({
      chart: { type: 'spline' },
      title: null,
      xAxis: {
        categories: $.map(keys,
                          function(val, i) {
                            return val.format("MMMM YYYY");
                          })
      },
      yAxis: { title: { text: t('highcharts.cnt_messages') } },
      series: [{
        name: t('highcharts.messages'),
        data: $.map(keys, function(val, i) { return dateAsKeys[val.year() + "-" + val.month()]; })
      }]
    });
  },

  registrations: {
    checkUsername: function() {
      var $uname = $("[data-js=username]");
      var uname = $uname.val();

      if(uname === '') {
        $uname.
          removeClass('failure').
          removeClass('success');

        $uname.
          parent().
          find("small").
          remove();

        return;
      }

      if(uname.indexOf("@") != -1) {
        $uname.
          addClass('failure').
          removeClass("success");

        var small = $uname.parent().find("small");

        if(small.length !== 0) {
          small.remove();
        }

        $uname.after("<small>" + t('no_at_in_name') + "</small>");
        return;
      }

      $.get(cforum.baseUrl + 'users.json?exact=' + encodeURIComponent(uname)).
        success(function(data) {
          var small;

          if(data.length === 0) {
            $uname.
              removeClass('failure').
              addClass("success");

            small = $uname.parent().find("small");

            if(small.length !== 0) {
              small.remove();
            }
          }
          else {
            $uname.
              addClass('failure').
              removeClass("success");

            if(small.length === 0) {
              $uname.after("<small>" + t('username_taken') + "</small>");
            }
          }
        });
    },

    new: function() {
      var tm = null;
      $("[data-js=username]").on('keyup', function() {
        if(tm != null) {
          window.clearTimeout(tm);
        }
        tm = window.setTimeout(cforum.users.registrations.checkUsername, 400);
      });
    }
  }
};

/* eof */
