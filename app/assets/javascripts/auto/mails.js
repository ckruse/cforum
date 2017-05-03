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

      for(node = node.next('tr'); node.length > 0 && !node.hasClass('fold-marker'); node = node.next()) {
          node.toggleClass('folded');
      }

      if($this.hasClass('open')) {
        $this.text('▶');
      }
      else {
        $this.text('▼');
      }

      $this.toggleClass('open');
      $this.parents('tbody').toggleClass('open');
    });
  },

  init: function() {
    cforum.messages.initMarkdown("priv_message_body");
    cforum.messages.initPreview("priv_message_body");
    cforum.replacements("#priv_message_body");
  },

  notifyNew: function(event, data) {
    var mails = $("#mails");
    var txt = mails.text();
    mails.addClass('new');

    if(txt) {
      mails.text(data.unread);

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
    cforum.events.on('mail:create', cforum.mails.notifyNew);
  }
});


/* eof */
