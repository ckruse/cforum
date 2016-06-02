/* -*- coding: utf-8 -*- */
/* global cforum */

cforum.mails = {
  index: function() {
    $("#check-all-box").on('change', function() {

      if($(this).is(":checked")) {
        $(".mid-checkbox").attr("checked","checked");
      }
      else {
        $(".mid-checkbox").removeAttr('checked');
      }

    });

    $('.fold-marker td:first-of-type').on('click', function() {
      var $this = $(this);
      var node = $this.closest('tr');

      for(node = node.next('tr'); !node.hasClass('fold-marker'); node = node.next()) {
        if(node.hasClass('folded')) {
          node.css('display', 'none').removeClass('folded').fadeIn('fast');
        }
        else {
          node.fadeOut('fast', function() { $(this).addClass('folded'); });
        }
      }

      if($this.hasClass('open')) {
        $this.removeClass('open');
        $this.text('▶');
      }
      else {
        $this.addClass('open');
        $this.text('▼');
      }
    });
  },

  init: function() {
    cforum.messages.initMarkdown("priv_message_body");
    cforum.messages.initPreview("priv_message_body");
  },

  notifyNew: function(data) {
    var mails = $("#mails");
    var txt = mails.text();
    mails.addClass('new');

    if(txt) {
      txt = parseInt(txt, 10);
      txt += 1;
      mails.text(txt);

      var title = mails.attr('title');
      title = title.replace(/\d+/, txt);
      mails.parent().children().attr('title', title);

      cforum.events.trigger("update", data);
      cforum.events.trigger("update:mail", data);
    }

    mails.animate({'font-size': '1.3em'}, 200, function() {
      mails.animate({'font-size': '1em'}, 200);
    });

    cforum.updateFavicon();
  }
};

$(function() {
  if(cforum.currentUser) {
    cforum.client.on('mail:create', cforum.mails.notifyNew);
  }
});


/* eof */
