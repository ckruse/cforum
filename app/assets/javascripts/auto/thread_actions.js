/* -*- coding: utf-8 -*- */
/* global cforum, t */

$(function() {
  $('.root').on('click', function(ev) {
    if(!cforum.currentUser) {
      return;
    }

    var $this = $(ev.target);
    var valid_elements = [
      '.icon-thread.mark-thread-read',
      '.icon-message.unread',
      '.icon-thread.closed',
      '.icon-thread.open',
      '.icon-message.mark-interesting',
      '.icon-message.mark-boring',
      '.icon-thread.mark-invisible',
      '.icon-thread.mark-visible',
      '.icon-message.subscribe',
      '.icon-message.unsubscribe'
    ];

    var i, handle_elem = false;

    for(i = 0; i < valid_elements.length; ++i) {
      if($this.is(valid_elements[i])) {
        handle_elem = true;
        break;
      }
    }

    if(!handle_elem) {
      return;
    }

    ev.preventDefault();

    $this.addClass("spinning");

    var article = $this.closest('article');
    var form = $this.closest('form');
    var action = form.attr('action');

    var data = '';

    form.find('input[type=hidden]').each(function() {
      var $f = $(this);
      data += '&' + encodeURIComponent($f.attr('name')) + '=' + encodeURIComponent($f.attr('value'));
    });

    data = data.substring(1);

    $this.blur();

    $.post(action + '.json', data).
      done(function(data) {
        if($this.is('.icon-thread.mark-invisible') || $this.is('.icon-thread.mark-visible')) {
          $this.removeClass("spinning");
          article.fadeOut('fast', function() { article.remove(); });
        }
        else {
          cforum.updateThread(article, data.slug,
                              !($('body').attr('data-controller') == 'messages' &&
                                !$this.is('.icon-thread.open') &&
                                !$this.is('.icon-thread.close')),
                              function(success) { $this.removeClass("spinning"); });
        }
      }).
      fail(function(xhr, textStatus, errorThrown) {
        $this.removeClass("spinning");
        cforum.alert.error(t('something_went_wrong'));
      });
  });
});

/* eof */
