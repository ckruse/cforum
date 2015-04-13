/* -*- coding: utf-8 -*- */
/* global cforum */

$(function() {
  $('.icon-vote-down, .icon-vote-up').on('click', function(ev) {
    var $this = $(ev.target);

    ev.preventDefault();

    var form = $this.closest('form');
    var action = form.attr('action');

    var data = '';

    form.find('input[type=hidden]').each(function() {
      var $f = $(this);
      data += '&' + encodeURIComponent($f.attr('name')) + '=' + encodeURIComponent($f.attr('value'));
    });

    data += '&type=' + $this.attr('value');
    data = data.substring(1);

    $.post(action + '.json', data).
      success(function(data) {
        if(data.status == 'success') {
          $this.toggleClass('active');
          cforum.alert.success(data.message);

          var votes = form.find('.votes');
          votes.text(data.score);

          var other_vote = form.find($this.is('.icon-vote-down') ? '.icon-vote-up' : '.icon-vote-down');
          other_vote.removeClass('active');
        }
        else {
          cforum.alert.error(data.message);
        }
      }).
      error(function() {
        cforum.alert.error('Etwas ist schief gegangen!');
      });

  });
});

/* eof */
