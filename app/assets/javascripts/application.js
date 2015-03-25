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
//= require init.js
//= require_tree .

/* global cforum */

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

// eof
