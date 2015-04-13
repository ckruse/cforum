/* -*- coding: utf-8 -*- */
/* global alert */

$(function() {
  $('.root').on('click', function(ev) {
    var $this = $(ev.target);
    var valid_elements = [
      '.icon-thread.mark-thread-read',
      '.icon-message.unread',
      '.icon-thread.closed',
      '.icon-thread.open',
      '.icon-thread.mark-interesting',
      '.icon-thread.mark-boring',
      '.icon-thread.mark-invisible'
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

    var article = $this.closest('article');
    var form = $this.closest('form');
    var action = form.attr('action');

    var data = '';

    form.find('input[type=hidden]').each(function() {
      var $f = $(this);
      data += '&' + encodeURIComponent($f.attr('name')) + '=' + encodeURIComponent($f.attr('value'));
    });

    data = data.substring(1);

    $.post(action + '.json', data).
      success(function(data) {
        if($this.is('.icon-thread.mark-invisible')) {
          article.fadeOut('fast', function() { article.remove(); });
        }
        else {
          $.get(data.location).
            success(function(content) { article.replaceWith(content); }).
            error(function() { alert.error('Etwas ist schief gegangen!'); });
        }
      }).
      error(function() {
        alert.error('Etwas ist schief gegangen!');
      });
  });
});

/* eof */
