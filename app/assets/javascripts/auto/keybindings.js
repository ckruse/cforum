/* -*- coding: utf-8 -*- */
/* global cforum, Mousetrap, uconf */

cforum.keybindings = {
  /*
   * keybindings for threads index
   */
  threads: function() {
    if(uconf('keybindings') != 'yes') {
      return;
    }

    var prevNextMsg = function(pos, onlyUnread) {
      var elements;
      if(onlyUnread) {
        elements = $("[data-js=threadlist] header:not(.visited) h2 a, [data-js=threadlist] li header:not(.visited) .details " + (uconf('hide_subjects_unchanged') == 'yes' ? ' .message-link' : 'h3 a'));
      }
      else {
        elements = $("[data-js=threadlist] header h2 a, [data-js=threadlist] li header .details " + (uconf('hide_subjects_unchanged') == 'yes' ? ' .message-link' : 'h3 a'));
      }

      var elem = cforum.keybindings.focusInElements(pos, elements);
      if('scrollIntoView' in elem[0]) {
        elem[0].scrollIntoView();
      }
    };

    /* next posting */
    Mousetrap.bind('j', function(ev) {
      ev.preventDefault();
      prevNextMsg(1, false);
    });

    /* previous posting */
    Mousetrap.bind('k', function(ev) {
      ev.preventDefault();
      prevNextMsg(-1, false);
    });

    /* next unread posting */
    Mousetrap.bind('J', function(ev) {
      ev.preventDefault();
      prevNextMsg(1, true);
    });

    /* prev unread posting */
    Mousetrap.bind('K', function(ev) {
      ev.preventDefault();
      prevNextMsg(-1, true);
    });
  },

  /*
   * keybindings for message view
   */
  messages: function() {
    if(uconf('keybindings') != 'yes') {
      return;
    }

    var prevNextPosting = function(pos, onlyUnread) {
      var nest = $(".thread-nested");

      if(nest.length !== 0) {
        var elements = nest.find(".posting-nested > header" +
                                 (onlyUnread ? ":not(.visited)" : "") +
                                 " > h2 > a, .posting-nested > header" +
                                 (onlyUnread ? ":not(.visited)" : "") + " > h3 > a");

        var elem = cforum.keybindings.focusInElements(pos, elements);

        if('scrollIntoView' in elem[0]) {
          elem[0].scrollIntoView();
        }

      }
      else {
        var tree;

        if(onlyUnread) {
          tree = $(".root header:not(.visited), .root header.active");
        }
        else {
          tree = $(".root header");
        }

        if(tree.length === 0) {
          return;
        }

        for(var i = 0; i < tree.length; ++i) {
          if($(tree[i]).hasClass('active') && i < tree.length - pos) {
            document.location.href = $(tree[i+pos]).find('.message-link').attr('href');
            return;
          }
        }

        if(pos == -1) {
          document.location.href = $(tree[tree.length - 1]).find('.message-link').attr('href');
        }
        else {
          document.location.href = $(tree[0]).find('.message-link').attr('href');
        }
      }
    };

    /* next posting */
    Mousetrap.bind('j', function(ev) {
      ev.preventDefault();
      prevNextPosting(1, false);
    });

    /* previous posting */
    Mousetrap.bind('k', function(ev) {
      ev.preventDefault();
      prevNextPosting(-1, false);
    });

    /* next unread posting */
    Mousetrap.bind('J', function(ev) {
      ev.preventDefault();
      prevNextPosting(1, true);
    });

    /* previous unread posting */
    Mousetrap.bind('K', function(ev) {
      ev.preventDefault();
      prevNextPosting(-1, true);
    });

    /* scroll active posting in thread tree into view */
    Mousetrap.bind('l', function(ev) {
      ev.preventDefault();
      var el = $(".root .active");
      el.focus();
      if('scrollIntoView' in el[0]) {
        el[0].scrollIntoView();
      }
    });

    /* reply */
    Mousetrap.bind('r', function(ev) {
      ev.preventDefault();

      var nest = $(".thread-nested"), post;

      if(nest.length === 0) {
        post = $;
      }
      else {
        post = $(".posting-nested h2 a:focus").closest('article');
      }

      document.location.href = post.find(".answer:not(.wo-quote)").attr('href');
    });

    /* reply w/o quote */
    Mousetrap.bind('R', function(ev) {
      var nest = $(".thread-nested"), post;

      if(nest.length === 0) {
        post = $;
      }
      else {
        post = $(".posting-nested .posting-content:appeared:first").parent();
      }

      document.location.href = post.find(".answer.wo-quote").attr('href');
    });
  },

  focusInElements: function(pos, elements) {
    if(elements.length === 0) {
      return $([]);
    }

    for(var i = 0; i < elements.length; ++i) {
      if($(elements[i]).is(':focus') && i < elements.length - pos) {
        $(elements[i + pos]).focus();
        return $(elements[i + pos]);
      }
    }

    if(pos < 0) {
      elements[elements.length - 1].focus();
      return $(elements[elements.length - 1]);
    }
    else {
      elements[0].focus();
      return $(elements[0]);
    }
  }
};

/* eof */
