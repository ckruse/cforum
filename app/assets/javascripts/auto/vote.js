/* -*- coding: utf-8 -*- */
/* global cforum, t */

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

    $this.blur();

    $.post(action + '.json', data).
      done(function(data) {
        if(data.status == 'success') {
          $this.toggleClass('active');
          cforum.alert.success(data.message);

          var votes = form.find('.votes');
          votes.text(data.score);

          var other_vote, title, title_this;

          if($this.is('.icon-vote-down')) {
            other_vote = form.find('.icon-vote-up');
            title = t('vote_up');
            title_this = $this.hasClass('active') ? t('take_back_vote') : t('vote_down');
          }
          else {
            other_vote = form.find('.icon-vote-down');
            title = t('vote_down');
            title_this = $this.hasClass('active') ? t('take_back_vote') : t('vote_up');
          }

          other_vote.removeClass('active');
          other_vote.attr('title', title);
          $this.attr('title', title_this);
        }
        else {
          cforum.alert.error(data.message);
        }
      }).
      fail(function(xhr, textStatus, errorThrown) {
        cforum.alert.error('Etwas ist schief gegangen!');
      });

  });
});

/* eof */
