/* -*- coding: utf-8 -*- */
/* global cforum, t, Highcharts */

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
      d = new Date(v.created_at);

      if(!min || d < min) {
        min = d;
      }

      if(!max || d > max) {
        max = d;
      }

      dateAsKeys[d.getYear() + "-" + d.getMonth()] = v.cnt;
    }

    var keys = [];
    for(d = min; d <= max; d.setMonth(d.getMonth() + 1)) {
      var curKey = d.getYear() + "-" + d.getMonth();
      keys.push(new Date(d));

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
                            return Highcharts.dateFormat("%B %Y",
                                                         new Date(val));
                          })
      },
      yAxis: { title: { text: t('highcharts.cnt_messages') } },
      series: [{
        name: t('highcharts.messages'),
        data: $.map(keys, function(val, i) { return dateAsKeys[val.getYear() + "-" + val.getMonth()]; })
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
