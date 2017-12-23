/* -*- coding: utf-8 -*- */
/* global cforum, t, uconf, MathJax, Mustache */

cforum.messages = {
  initMarkdown: function(elem_id) {
    var elem = $("#" + elem_id);

    if(elem.length) {
      cforum.markdown_buttons.l10n();

      elem.markdown({autofocus: false, savable: false, iconlibrary: 'fa',
                     language: 'de', hiddenButtons: 'cmdPreview',
                     disabledButtons: 'cmdPreview', resize: 'both',
                     fullscreen: { enable: false },
                     additionalButtons: [
                       {
                         name: 'groupCustom',
                         data: [
                           cforum.markdown_buttons.noMarkdown,
                           cforum.markdown_buttons.tab
                         ]
                       }
                     ]});

      $(".btn-group.groupFont").before("<div class=\"btn-group groupHelp\"><a href=\"https://wiki.selfhtml.org/wiki/SELFHTML:Forum/Formatierung_der_Beitr%C3%A4ge\" class=\"btn-default btn-sm btn forum-usage\" title=\"" + t("help") + "\"><span class=\"icon-help\"></span></a></div>");
    }
  },

  maxLen: function(text) {
    var newlines = 0;

    for(var i = 0; i < text.length; ++i) {
      if(text.charAt(i) == "\n") {
        newlines++;

        if(newlines >= 3 && i >= 100) {
          return text.substr(0, i);
        }
      }

      if(i > 300) {
        return text.substr(0, i);
      }
    }

    return null;
  },

  initQuotes: function() {
    if(uconf('fold_quotes') != 'yes') {
      return;
    }

    $(".posting-content blockquote").each(function() {
      var $this = $(this);
      var txt = cforum.messages.maxLen($this.text());

      if(txt) {
        $this.css('display', 'none');
        $this.before('<blockquote class="show-quotes"><br>\n<span class="unfold">' + t('unfold_quote') + '</span></blockquote>');
        $this.prev().prepend(document.createTextNode(txt));
      }
    });

    $(".posting-content").click(function(ev) {
      var trg = $(ev.target);
      if(trg.hasClass('unfold')) {
        trg.parent().next().fadeIn('fast');
        trg.parent().remove();
      }
    });
  },

  show: function() {
    cforum.messages.hideBadScored();

    if(uconf('fold_read_nested') == 'yes' && !cforum.viewAll) {
      var nodes = $('.posting-nested.folded');

      if(nodes.length > 0) {
        $('body').append('<div id="unfold-all">Alle ausklappen</div>');

        $("#unfold-all").on('click', function() {
          $('.posting-nested.folded').removeClass('folded');
          $(this).remove();

          if(window.scrollTo) {
            var anchor = document.location.hash;
            if(anchor) {
              var offset = $(anchor).offset();
              window.scrollTo(offset.left, offset.top);
            }
          }
        });


        $(".thread-nested").on('click', function(ev) {
          var trg = $(ev.target);

          if(!trg.is(".posting-nested")) {
            trg = trg.closest('.posting-nested');
          }

          if(trg.hasClass('folded')) {
            ev.preventDefault();
            trg.removeClass('folded');

            if($(".posting-nested.folded").length <= 0) {
              $("#unfold-all").remove();
            }
          }
        });
      }
    }

    if($('body').hasClass('nested-view') && history.pushState) {
      $('.root a').on('click', function(event) {
        var $this = $(this);

        if($this.attr('href').match(/\/\w+\/\d+\/\w+\/\d+\/[^\/]+\/(\d+)#m\d+/)) {
          var mid = RegExp.$1;

          if(document.location.href.match(/\/\w+\/\d+\/\w+\/\d+\/[^\/]+\/(\d+)#m\d+/)) {
            var old_mid = RegExp.$1;

            if(old_mid != mid) {
              var new_url = document.location.href.replace(/\d+#m\d+/, mid + "#m" + mid);
              event.preventDefault();
              history.pushState(mid, "", new_url);

              if(uconf('fold_read_nested') == 'yes' && !cforum.viewAll) {
                $("#m" + old_mid).closest('.posting-nested').addClass('folded');
                $("#m" + mid).closest('.posting-nested').removeClass('folded');
              }

              $("html,body").scrollTop($("#m" + mid).offset().top);
            }
          }
        }
      });
    }

    $(".subscribe-message, .unsubscribe-message").closest("form").on("submit", function(ev) {
      if($(ev.target).find("button").hasClass("subscribe-message")) {
        cforum.messages.subscribeMessage(ev);
      }
      else {
        cforum.messages.unsubscribeMessage(ev);
      }
    });

    $("button.mark-interesting, button.mark-boring").closest("form").on("submit", function(ev) {
      if($(ev.target).find("button").hasClass("mark-interesting")) {
        cforum.messages.markInteresting(ev);
      }
      else {
        cforum.messages.markBoring(ev);
      }
    });

    if(uconf('inline_answer') != 'no') {
      cforum.messages.inlineReply($("body").hasClass("nested-view"));
    }
  },

  setTags: function(msg) {
    $("#tags-list").html("");

    msg.find("> .posting-header .cf-tag").each(function() {
      var val = $(this).text();
      cforum.tags.appendTag(val);
      cforum.tags.events.trigger('tags:add-tag', val);
    });
  },

  inlineReply: function(nested) {
    if(uconf('quote_by_default') != 'yes') {
      $(".btn-group.groupCustom").append("<button class=\"btn-default btn-sm btn quote-message\">" + t('add_quote') + "</button>");
      $('.btn-group.groupCustom .quote-message').on('click', cforum.messages.quoteMessage);
    }

    $(".btn-answer").on('click', function(ev) {
      ev.preventDefault();

      var $trg = $(ev.target);
      var $frm = $(".cf-form.inline-answer");
      var msg = $(ev.target).closest('.thread-message');
      var node = msg.find("> .posting-header > .message > h3 a");
      var q_url;
      if(node.length === 0) {
        node = msg.find("> .posting-header > .message > h2 a");
      }

      $frm.attr("action", node.attr('href').replace(/#m\d+$/, ''));

      if(nested) {
        $trg.addClass("spinning");

        cforum.messages.setTags(msg);

        $frm.detach();
        $frm.insertAfter(msg);

        $frm.find("#message_subject").val(node.text());
        $frm.find("#message_problematic_site").val(msg.find(".problematic-site a").attr('href'));

        q_url = node.attr("href");
        q_url = q_url.replace(/#m\d+$/, '');
        q_url = q_url.replace(/\?.*/, '');
        q_url += "/quote";

        if($trg.hasClass("with-quote")) {
          q_url += "?quote=yes";
        }
        else {
          q_url += '?quote=' + uconf("quote_by_default");
        }

        cforum.messages.getQuote(q_url, $frm, $trg);
      }
      else {
        if(uconf('quote_by_default') == 'button') {
          q_url = $frm.attr("action");
          q_url = q_url.replace(/\?.*/, '');
          q_url += "/quote";

          if($trg.hasClass("with-quote")) {
            q_url += "?quote=yes";
          }
          else {
            q_url += '?quote=' + uconf("quote_by_default");
          }

          cforum.messages.getQuote(q_url, $frm, $trg);
        }
        else {
          $frm
            .removeClass("hidden")
            .fadeIn('fast');

          if(window.scrollTo) {
            var offset = $("#message_input").closest("fieldset").offset();
            window.scrollTo(offset.left, offset.top);
          }

          cforum.messages.initCursor();
          cforum.messages.showPreview("message_input", "message_problematic_site");
        }
      }
    });

    $(".btn-cancel").on('click', function(ev) {
      ev.preventDefault();
      $(".cf-form.inline-answer").fadeOut('fast');
    });
  },

  getQuote: function(url, frm, bttn) {
    $.get(url)
      .done(function(data) {
        $("#message_input").val(data);

        frm
          .removeClass("hidden")
          .fadeIn('fast');

        if(window.scrollTo) {
          var offset = $("#message_input").closest("fieldset").offset();
          window.scrollTo(offset.left, offset.top);
        }

        cforum.messages.initCursor();
        cforum.messages.showPreview("message_input", "message_problematic_site");

        if(bttn.hasClass('with-quote')) {
          $('.btn-group.groupCustom .quote-message').remove();
        }

        bttn.removeClass("spinning");
      })
      .fail(function() {
        bttn.removeClass("spinning");
        cforum.alert.error(t('something_went_wrong'));
      });
  },

  subscribeMessage: function(ev) {
    ev.preventDefault();
    var form = $(ev.target);
    var url = form.attr("action");
    var btn = form.find("button");

    btn.addClass("loading");

    $.post(url + '.json').
      done(function(data) {
        form.attr("action", url.replace(/subscribe$/, 'unsubscribe'));

        btn.text(t('subscriptions.unsubscribe'));
        btn.removeClass("subscribe-message").addClass("unsubscribe-message").removeClass("loading");

        cforum.updateThread($(".root article"), data.slug, false);
      }).
      fail(function() {
        btn.removeClass("loading");
        cforum.alert.error(t('something_went_wrong'));
      });
  },

  unsubscribeMessage: function(ev) {
    ev.preventDefault();
    var form = $(ev.target);
    var url = form.attr("action");
    var btn = form.find("button");

    btn.addClass("loading");

    $.post(url + '.json').
      done(function(data) {
        form.attr("action", url.replace(/unsubscribe$/, 'subscribe'));

        var btn = form.find("button");
        btn.text(t('subscriptions.subscribe'));
        btn.removeClass("unsubscribe-message").addClass("subscribe-message").removeClass("loading");

        cforum.updateThread($(".root article"), data.slug, false);
      }).
      fail(function() {
        btn.removeClass("loading");
        cforum.alert.error(t('something_went_wrong'));
      });
  },

  markInteresting: function(ev) {
    ev.preventDefault();
    var form = $(ev.target);
    var url = form.attr("action");
    var btn = form.find("button");

    btn.addClass("loading");

    $.post(url + '.json').
      done(function(data) {
        form.attr("action", url.replace(/interesting$/, 'boring'));

        var btn = form.find("button");
        btn.text(t('interesting.mark_message_boring'));
        btn.removeClass("mark-interesting").addClass("mark-boring").removeClass("loading");

        cforum.updateThread($(".root article"), data.slug, false);
      }).
      fail(function() {
        btn.removeClass("loading");
        cforum.alert.error(t('something_went_wrong'));
      });
  },

  markBoring: function(ev) {
    ev.preventDefault();
    var form = $(ev.target);
    var url = form.attr("action");
    var btn = form.find("button");

    btn.addClass("loading");

    $.post(url + '.json').
      done(function(data) {
        form.attr("action", url.replace(/boring$/, 'interesting'));

        var btn = form.find("button");
        btn.text(t('interesting.mark_message_interesting'));
        btn.removeClass("mark-boring").addClass("mark-interesting").removeClass("loading");

        cforum.updateThread($(".root article"), data.slug, false);
      }).
      fail(function() {
        btn.removeClass("loading");
        cforum.alert.error(t('something_went_wrong'));
      });
  },

  init: function() {
    var action = $('body').attr('data-action');
    cforum.tags.initTags();
    cforum.messages.initQuotes();

    if(action != 'create' && action != 'update') {
      cforum.messages.initCursor();
    }

    cforum.messages.initMarkdown("message_input");
    cforum.messages.initPreview("message_input", "message_problematic_site");
    cforum.messages.initMaxLengthWarnings();
    cforum.replacements("#message_input", true);
    cforum.messages.initEmojis("#message_input", ".btn-group.groupUtil");
  },

  initEmojis: function(area, group) {
    $(group).append('<button class="md-editor-open-replacements btn-default btn-sm btn">😀</button>');
    $(".md-editor-open-replacements").on('click', function(ev) {
      ev.preventDefault();
      $(area).focus();

      // we have to wait for the re-focus
      window.setTimeout(function() {
        $(area).textcomplete('trigger', '::');
        $(area).data('is-btn', true);
      }, 0);
    });
  },

  new: function() {
    if(uconf("quote_by_default") != 'yes') {
      $(".btn-group.groupCustom").append("<button class=\"btn-default btn-sm btn quote-message\">" + t('add_quote') + "</button>");
      $('.btn-group.groupCustom .quote-message').on('click', cforum.messages.quoteMessage);
    }
  },

  quoteMessage: function(ev) {
    ev.preventDefault();

    var $msg = $("#message_input");

    var url = $(".answer-form").attr("action");
    url = url.replace(/#m\d+$/, '');
    url = url.replace(/\?.*/, '');
    url += "/quote";

    $.get(url + '?only_quote=yes')
      .done(function(data) {
        var selection = $msg.getSelection();
        $msg.replaceSelection(data);
        $msg.change();

        $msg.focus();
        $msg.setSelection(selection.start, selection.start);

        $('.btn-group.groupCustom .quote-message').remove();
      })
      .fail(function() {
        $(ev.target).removeClass("spinning");
        cforum.alert.error(t('something_went_wrong'));
      });
  },

  initCursor: function() {
    var content = $("#message_input");
    var subj = $("#message_subject");
    var author = $("#message_author");

    cforum.cf_threads.setCursor(author, subj, content);
  },

  previewTimeout: null,
  oldVal: null,
  oldUrl: null,
  initPreview: function(name, problematicUrlName) {
    if(uconf('live_preview') != 'yes') {
      return;
    }

    var frm = $("#" + name).closest("form");
    var btt = frm.find("[type=submit]");
    btt.on('mouseenter focus', function() { $(".thread-message.preview").addClass('active'); });
    btt.on('mouseleave blur', function() {
      if(frm.find("[type=submit]:hover").length <= 0 && !btt.is(":focus")) {
        $(".thread-message.preview").removeClass('active');
      }
    });

    if(frm.is(":visible")) {
      cforum.messages.showPreview(name, problematicUrlName);
    }

    $("input[name=preview]").remove();

    var f = function() {
      if(cforum.messages.previewTimeout) {
        window.clearTimeout(cforum.messages.previewTimeout);
        cforum.messages.previewTimeout = null;
      }

      cforum.messages.previewTimeout = window.setTimeout(function() {
        cforum.messages.showPreview(name, problematicUrlName);
      }, 500);
    };

    var str = "#" + name;
    if(problematicUrlName) {
      str += ", #" + problematicUrlName;
    }

    $(str).on('input change', f);
  },
  showPreview: function(name, problematicUrlName) {
    var val = $("#" + name).val();
    var problematicUrl = $("#" + problematicUrlName).val();

    if(cforum.messages.oldVal != val || cforum.messages.oldUrl != problematicUrl) {
      cforum.messages.oldVal = val;
      cforum.messages.oldUrl = problematicUrl;

      if(problematicUrl) {
        var elem = $(".thread-message.preview").find(".problematic-site");
        if(elem.length <= 0) {
          $("#on-the-fly-preview").before("<p class=\"problematic-site\"></p>");
          elem = $(".thread-message.preview").find(".problematic-site");
        }
        elem.html("<a href=\"" + Mustache.escapeHtml(problematicUrl) + "\">" + t("problematic_site") + "</a>");
      }
      else {
        $(".thread-message.preview").find(".problematic-site").remove();
      }

      $.post(cforum.baseUrl + 'preview',
             {content: val}).
        done(function(data) {
          $("#on-the-fly-preview").html(data);

          if(typeof window.MathJax !== 'undefined') {
            MathJax.Hub.Queue(["Typeset", MathJax.Hub]);
          }
        });
    }
  },

  initMaxLengthWarnings: function() {
    var minput = $("#message_input");
    var maxLen = minput.attr('maxlength');

    if(!minput.length) {
      return;
    }

    minput.before("<div class=\"character-count-container\" aria-live=\"polite\"><span class=\"message-character-count\"></span></div>");
    var mcount = $(".message-character-count");

    var checkLength = function() {
      // we need to work on \015\012 line endings because HTTP defines
      // this as the correct line endings; Safari and Chrome, on the
      // other hand, work with natural line endings when getting the
      // value but with \015\012 when checking for maxlength firefox,
      // on the other hand, is consistent (it uses natural line
      // endings for both) but totally insane…
      var val = minput.val().replace(/\015\012|\012|\015/g, "\015\012");
      var len = val.length;

      mcount.text(len + " / " + maxLen);

      if(len >= maxLen) {
        minput.addClass('length-error').removeClass('length-warning');
        mcount.addClass('length-error').removeClass('length-warning');
      }
      else if(len >= maxLen - 300) {
        minput.addClass('length-warning').removeClass('length-error');
        mcount.addClass('length-warning').removeClass('length-error');
      }
      else {
        minput.removeClass('length-warning').removeClass('length-error');
        mcount.removeClass('length-warning').removeClass('length-error');
      }
    };

    checkLength();
    minput.on('keyup', checkLength);
  },

  twitter: {
    new: function() {
      var minput = $("#tweet_text");
      var maxLen = 280;

      if(!minput.length) {
        return;
      }

      minput.before("<div class=\"twitter-character-count-container\"><span class=\"twitter-message-character-count\"></span></div>");
      var mcount = $(".twitter-message-character-count");

      var cleanup = function(text) {
        text = text.replace(/\015\012|\012|\015/g, "\012");
        // this is naive but enough for a length check
        text = text.replace(/https?:\/\/[a-zA-Z0-9:\/&+_,;%.-]+/g, '');
        text = text.replace(/#[a-zA-Z0-9]+/g, "");

        return text;
      };

      var checkLength = function() {
        var val = cleanup(minput.val());
        var len = val.length;

        mcount.text(len + " / " + maxLen);

        if(len >= maxLen) {
          minput.addClass('length-error').removeClass('length-warning');
          mcount.addClass('length-error').removeClass('length-warning');
        }
        else if(len >= maxLen - 40) {
          minput.addClass('length-warning').removeClass('length-error');
          mcount.addClass('length-warning').removeClass('length-error');
        }
        else {
          minput.removeClass('length-warning').removeClass('length-error');
          mcount.removeClass('length-warning').removeClass('length-error');
        }
      };

      checkLength();
      minput.on('keyup', checkLength);
    }
  },

  split_thread: {
    init: function() {
      cforum.tags.initTags();
    }
  },

  hideBadScored: function() {
    $(".thread-nested .negative-bad-score").each(function() {
      var $this = $(this);
      var author = $this.find(".author").html();
      var header = $this.find("header");
      var id = header.attr("id");
      $this.css('display', 'none');
      header.removeAttr("id");
      $this.before("<div id=\"" + id + "\" class=\"hidden-posting\">" + author + " <span class=\"score-to-low-note\">" + t('score_to_low') + "</div>");
    });

    $(".hidden-posting .author-email, .hidden-posting .author-homepage").remove();
    $(".hidden-posting .score-to-low-note").on('click', function() {
      var $this = $(this).closest(".hidden-posting");
      var msg = $this.next();
      var id = $this.attr("id");

      $this.removeAttr("id");
      msg.find("header").attr("id", id);
      msg.removeClass("folded");
      msg.fadeIn('fast');

      $this.fadeOut('fast', function() { $this.remove(); });
    });
  }
};

/* eof */
