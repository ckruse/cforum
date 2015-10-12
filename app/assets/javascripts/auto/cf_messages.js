/* -*- coding: utf-8 -*- */
/* global cforum, t, uconf */

cforum.cf_messages = {
  initMarkdown: function(elem_id) {
    var elem = $("#" + elem_id);

    if(elem.length) {
      cforum.markdown_buttons.l10n();

      elem.markdown({autofocus: false, savable: false, iconlibrary: 'fa',
                     language: 'de', hiddenButtons: 'cmdPreview',
                     disabledButtons: 'cmdPreview', resize: 'both',
                     additionalButtons: [
                       {
                         name: 'groupCustom',
                         data: [
                           cforum.markdown_buttons.noMarkdown,
                           cforum.markdown_buttons.tab,
                           cforum.markdown_buttons.hellip,
                           cforum.markdown_buttons.mdash,
                           cforum.markdown_buttons.almostEqualTo,
                           cforum.markdown_buttons.unequal,
                           cforum.markdown_buttons.times,
                           cforum.markdown_buttons.arrowRight,
                           cforum.markdown_buttons.arrowUp,
                           cforum.markdown_buttons.blackUpPointingTriangle,
                           cforum.markdown_buttons.rightwardsDoubleArrow,
                           cforum.markdown_buttons.trademark,
                           cforum.markdown_buttons.doublePunctuationMarks,
                           cforum.markdown_buttons.singlePunctuationMarks
                         ]
                       }
                     ]});

      var usg = $('#forum-usage');
      if(usg.length > 0) {
        elem.prev().append(usg);
      }
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
      var txt = cforum.cf_messages.maxLen($this.text());

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

  init: function() {
    var action = $('body').attr('data-action');
    cforum.tags.initTags();
    cforum.cf_messages.initQuotes();

    if(action != 'create' && action != 'update') {
      cforum.cf_messages.initCursor();
    }

    cforum.cf_messages.initMarkdown("message_input");
    cforum.cf_messages.initUpload();
    cforum.cf_messages.initPreview();
    $("#message_input").mentions();
  },

  new: function() {
    if(cforum.cf_messages.quotedMessage) {
      $(".form-actions").append("<button class=\"cf-btn quote-message\">" + t('add_quote') + "</button>");
      $('.form-actions .quote-message').on('click', cforum.cf_messages.quoteMessage);
    }
  },

  quoteMessage: function(ev) {
    ev.preventDefault();
    $("#message_input").val($("#message_input").val() + cforum.cf_messages.quotedMessage);
    $(".form-actions .quote-message").fadeOut('fast', function() { $(this).remove(); });
  },

  initCursor: function() {
    var content = $("#message_input");
    var subj = $("#cf_message_subject");
    var author = $("#cf_message_author");

    cforum.cf_threads.setCursor(author, subj, content);
  },

  initUpload: function() {
    if($("#message_input").length > 0 && window.Dropzone) {
      $("#message_input").after('<div class="image-upload">' + t('upload.image_area') + '</div>');
      $(".image-upload").dropzone({
        createImageThumbnails: false,
        maxFilesize: 2, // 2mb max filesize
        url: cforum.baseUrl + 'images.json',
        clickable: true,
        acceptedFiles: 'image/*',
        previewTemplate : '<div style="display:none"></div>',
        fallback: function() { },
        init: function() {
          this.on("success", function(file, rsp) {
            var $msg = $("#message_input");
            var selection = $msg.getSelection();
            var md = '![' + t('upload.alternative_text') + '](' + cforum.basePath + 'images/' + rsp.path + ')';

            var imgup = $('.image-upload');
            imgup.removeClass('loading');
            imgup.html(t('upload.image_area'));

            $msg.replaceSelection(md);

            window.setTimeout(function() {
              $msg.focus();
              $msg.setSelection(selection.start + 2, selection.start + 17);
            }, 0);
          });

          this.on('error', function(file, response) {
            var imgup = $('.image-upload');
            imgup.removeClass('loading');
            imgup.html(t('upload.image_area'));
            cforum.alert.error(response.error || t('internal_error'));
          });

          this.on('sending', function(file, xhr, formData) {
            var imgup = $('.image-upload');
            imgup.addClass('loading');
            imgup.html("");

            xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'));
          });
        }
      });
    }
  },

  previewTimeout: null,
  initPreview: function() {
    cforum.cf_messages.showPreview();
    $("#message_input").on('keyup', function() {
      if(cforum.cf_messages.previewTimeout) {
        window.clearTimeout(cforum.cf_messages.previewTimeout);
        cforum.cf_messages.previewTimeout = null;
      }

      cforum.cf_messages.previewTimeout = window.setTimeout(cforum.cf_messages.showPreview, 500);
    });
  },
  showPreview: function() {
    $.post(cforum.baseUrl + 'preview',
           {content: $("#message_input").val()}).
      done(function(data) {
        $("#on-the-fly-preview").html(data);
      });
  }
};

/* eof */
