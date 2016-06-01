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
    $this.addClass("spinning");

    $.post(action + '.json', data).
      done(function(data) {
        $this.removeClass("spinning");

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
        $this.removeClass("spinning");
        cforum.alert.error('Etwas ist schief gegangen!');
      });

  });

  $(".cf-btn.accept").on("click", function(ev) {
    ev.preventDefault();
    ev.stopPropagation();

    var $this = $(ev.target);
    var action = $this.attr("href");

    $this.addClass("spinning");
    $this.blur();

    $.post(action + ".json").
      done(function(data) {
        $this.removeClass("spinning");

        if(data.status == 'success') {
          cforum.alert.success(data.message);

          if($this.hasClass("unaccepted-answer")) {
            $this.removeClass("unaccepted-answer").addClass("accepted-answer");
          }
          else {
            $this.removeClass("accepted-answer").addClass("unaccepted-answer");
          }
        }
      }).
      fail(function() {
        $this.removeClass("spinning");
        cforum.alert.error('Etwas ist schief gegangen!');
      });
  });
});

/* eof */
