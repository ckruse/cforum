// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs
//= require jquery-ui
//= require markdown/bootstrap-markdown.js
//= require markdown/bootstrap-markdown.de.js
//= require MathJax.js
//= require TeX-AMS-MML_SVG.js
//= require jax.js
//= require fontdata.js
//= require init.js
//= require_tree .

/* global cforum, MathJax */

function hasLocalstorage() {
  try {
    return 'localStorage' in window && window['localStorage'] !== null;
  }
  catch (e) {
    return false;
  }
}

function t(key, deflt) {
  var pieces = key.split('.');
  var loc = cforum.l10n;

  for(var i = 0; i < pieces.length; ++i) {
    if(loc[pieces[i]]) {
      loc = loc[pieces[i]];
    }
    else {
      if(deflt) {
        return deflt;
      }

      return "translation missing: " + key;
    }
  }

  return loc;
}

function setDismissHandlers() {
  $("[data-dismiss]").click(function() {
    var $this = $(this);
    var clss = $this.attr('data-dismiss');

    var elem = $this.closest("." + clss);
    elem.fadeOut('fast', function() { $(this).remove(); });
  });

  $("[data-dismiss]").each(function() {
    var $this = $(this);
    var clss = $this.attr('data-dismiss');

    $this.closest("." + clss).on('click', function() {
      $(this).fadeOut('fast', function() { $(this).remove(); });
    });
  });
}

function autohideAlerts() {
  window.setTimeout(function() {
    $(".cf-success").fadeOut('fast', function() { $(this).remove(); });
  }, 3000);
}

$(function() {
  setDismissHandlers();
  $(".select2").select2({minimumResultsForSearch: -1});
  $("form").dependentQuestions();

  $("#forum-list select").on('change', function() {
    if($(this).val() != "") {
      $("#forum-list").submit();
    }
  });

  autohideAlerts();
  $("textarea").tabEnable();
});

cforum.alert = {
  alert: function(text, type) {
    var alrt = $("<div class=\"" + type + " cf-alert\"><button type=\"button\" class=\"close\" data-dismiss=\"cf-alert\" aria-label=\"Close\"><span aria-hidden=\"true\">&times;</span></button></div>");
    alrt.text(text);
    $("#alerts-container").append(alrt);
    setDismissHandlers();

    window.setTimeout(function () { alrt.fadeOut('fast', function() { $(this).remove(); }); }, 3000);
  },

  error: function(text) {
    cforum.alert.alert(text, 'cf-error');
  },

  success: function(text) {
    cforum.alert.alert(text, 'cf-success');
  }
};

MathJax.Hub.Config({
  displayAlign: "left",
  menuSettings: { CHTMLpreview: false },
  tex2jax: {
    inlineMath: [],
    displayMath: []
  }
});


// eof
