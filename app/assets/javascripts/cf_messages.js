/* -*- coding: utf-8 -*- */
/* global cforum, t */

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
    }
  },

  maxLen: function(text) {
    return text.length > 100;
  },

  initQuotes: function() {
    if(!cforum.currentUser || cforum.currentUser.settings.options.fold_quotes != 'yes') {
      return;
    }

    $(".posting-content blockquote").each(function() {
      var $this = $(this);

      if(cforum.cf_messages.maxLen($this.text())) {
        $this.css('display', 'none');
        $this.before('<blockquote class="show-quotes">' + t('unfold_quote') + '</blockquote>');
      }
    });

    $(".posting-content").click(function(ev) {
      var trg = $(ev.target);
      if(trg.hasClass('show-quotes')) {
        trg.next().fadeIn('fast');
        trg.remove();
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
  }
};

/* eof */
