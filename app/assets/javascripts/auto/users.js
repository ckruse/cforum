/* -*- coding: utf-8 -*- */
/* global cforum */

cforum.users = {
  messagesByMonths: null,

  show: function() {
    Highcharts.setOptions({
      lang: t('highcharts')
    });

    var keys = cforum.users.messagesByMonths.sort(function(a,b) {
      var a_date = new Date(a.created_at);
      var b_date = new Date(b.created_at);
      return a_date.getTime() - b_date.getTime();
    });

    $("#user-activity-stats").highcharts({
      chart: { type: 'spline' },
      title: null,
      xAxis: {
        categories: $.map(keys,
                          function(val, i) {
                            return Highcharts.dateFormat("%B %Y",
                                                         new Date(val.created_at));
                          })
      },
      yAxis: { title: { text: t('highcharts.cnt_messages') } },
      series: [{
        name: t('highcharts.messages'),
        data: $.map(keys, function(val, i) { return val.cnt; })
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
