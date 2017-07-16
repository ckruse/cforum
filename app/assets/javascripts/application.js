// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery2
//= require confirmations.js
//= require jquery_ujs
//= require jquery-ui/widgets/autocomplete
//= require markdown/bootstrap-markdown.js
//= require markdown/bootstrap-markdown.de.js
//= require init.js
//= require_tree ./auto/

/* global cforum */

function hasLocalstorage() {
  try {
    localStorage.setItem('test', 'test'), localStorage.removeItem('test');
    return true;
  }
  catch (exception) {
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

function uconf(name) {
  var val;

  if(cforum.currentUser && cforum.currentUser.settings && cforum.currentUser.settings.options) {
    val = cforum.currentUser.settings.options[name];
  }

  if(typeof val == 'undefined') {
    val = cforum.settingDefaults[name];
  }

  return val;
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
  $("form").dependentQuestions();
  $(".dropdown").dropdown();

  autohideAlerts();
  $("textarea").tabEnable();

  $(window).on('focus', function() {
    cforum.resetFavicon();
  });
});

cforum.alert = {
  alert: function(text, type) {
    var alert = $('<div class="' + type + ' cf-alert"><button type="button" class="close" data-dismiss="cf-alert" aria-label="Close"><span aria-hidden="true">&times;</span></button></div>');
    alert.text(text);

    $('#alerts-container').append(alert);
    setDismissHandlers();

    window.setTimeout(function () {
      alert.fadeOut('fast', function() {
        $(this).remove();
      });
    }, 3000);
  },

  error: function(text) {
    cforum.alert.alert(text, 'cf-error');
  },

  success: function(text) {
    cforum.alert.alert(text, 'cf-success');
  }
};

cforum.updateTitle = function() {
  var title = document.title.replace(/^\([\d\/]+\) /, '');

  if(title != document.title) {
    $.get(cforum.baseUrl + 'forums_titles.json').
      done(function(data) {
        if(data.title) {
          document.title = data.title + title;
        }
      });
  }
};

cforum.updateFavicon = function() {
  var favicon = $('link[rel="shortcut icon"]');
  if(favicon.attr('href') != cforum.faviconUrl) {
    favicon.remove();
    $('head').append('<link rel="shortcut icon" type="image/x-icon" href="' + cforum.faviconUrl + '">');
  }

  cforum.updateTitle();
};

cforum.resetFavicon = function() {
  var favicon = $('link[rel="shortcut icon"]');
  if(favicon.attr('href') != '//src.selfhtml.org/favicon2.ico') {
    favicon.remove();
    $('head').append('<link rel="shortcut icon" type="image/x-icon" href="//src.selfhtml.org/favicon2.ico">');
  }

  cforum.updateTitle();
};

cforum.updateThread = function(thread, slug, fold, callback) {
  var loc = cforum.baseUrl + (cforum.currentForum ? cforum.currentForum.slug : 'all') + '/' + slug;

  if(!fold) {
    loc += '?fold=false';
  }

  $.get(loc).
    done(function(content) {
      thread.replaceWith(content);

      if(callback) {
        callback(true);
      }
    }).
    fail(function() {
      cforum.alert.error(t('something_went_wrong'));

      if(callback) {
        callback(false);
      }
    });
};
// eof
