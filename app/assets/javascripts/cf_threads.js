/* -*- coding: utf-8 -*- */
/* global cforum, Mustache, t, setDismissHandlers, autohideAlerts, hasLocalstorage, uconf */

cforum.cf_threads = {
  numThreads: 0,
  numMessages: 0,
  newMessages: [],

  new: function() {
    cforum.cf_threads.initGlobal();

    cforum.tags.initTags();
    cforum.cf_threads.initCursor();

    cforum.cf_messages.initMarkdown("message_input");
    cforum.cf_messages.initUpload();
    $("#message_input").mentions();
  },
  create: function() {
    cforum.cf_threads.initGlobal();

    cforum.tags.initTags();
    cforum.cf_messages.initMarkdown("message_input");
    cforum.cf_messages.initUpload();
    $("#message_input").mentions();
  },

  index: function() {
    var path = '/threads/' + (cforum.currentForum ? cforum.currentForum.slug : 'all');
    cforum.client.subscribe(path, cforum.cf_threads.newThreadArriving);

    path = '/messages/' + (cforum.currentForum ? cforum.currentForum.slug : 'all');
    cforum.client.subscribe(path, cforum.cf_threads.newMessageArriving);

    if(!cforum.currentUser) {
      cforum.cf_threads.initOpenClose();
    }
  },

  showNewAlert: function() {
    var alert = $("#new_messages_arrived");
    var append = false;

    if(!alert.length) {
      alert = $("<div class=\"cf-success cf-alert\" id=\"new_messages_arrived\"><button type=\"button\" class=\"close\" data-dismiss=\"cf-alert\" aria-label=\"Close\"><span aria-hidden=\"true\">&times;</span></button></div>");
      append = true;
    }

    alert.text(Mustache.render(
      t('messages_threads'),
      {threads: cforum.cf_threads.numThreads,
       messages: cforum.cf_threads.numMessages}));

    if(append) {
      $("#alerts-container").append(alert);
      setDismissHandlers();
      autohideAlerts();
    }
  },

  showNewThread: function(message) {
    var sortMethod = uconf('sort_threads');

    if(sortMethod != 'ascending' && sortMethod != 'descending' && sortMethod != 'newest-first') {
      sortMethod = 'descending';
    }

    var url = cforum.baseUrl +
          (cforum.currentForum ? cforum.currentForum.slug : 'all') +
          message.thread.slug;


    $.get(url).
      done(function(data) {
        switch(sortMethod) {
        case 'newest-first':
        case 'descending':
          if(document.location.href.indexOf('p=0') != -1 || document.location.href.indexOf('p=') == -1) {
            $("[data-js=threadlist]").prepend(data);
          }
          break;

        case 'ascending':
          if($(".cf-pages .last").hasClass('disabled')) {
            $("[data-js=threadlist]").append(data);
          }
          break;
        }

        cforum.cf_threads.newMessages.push(message.message.message_id);

        var m;
        for(var i = 0; i < cforum.cf_threads.newMessages.length; ++i) {
          m = $("#m" + cforum.cf_threads.newMessages[i]);
          if(!m.hasClass('new')) {
            m.addClass('new');
          }
        }
      });
  },

  newThreadArriving: function(message) {
    cforum.cf_threads.numThreads += 1;
    cforum.cf_threads.numMessages += 1;

    if(cforum.currentUser && message.message.user_id == cforum.currentUser.user_id) {
      return;
    }

    if(uconf('load_messages_via_js') != 'no') {
      cforum.cf_threads.showNewThread(message);
    }

    cforum.cf_threads.showNewAlert();
    cforum.updateFavicon();
  },

  newMessageArriving: function(message) {
    cforum.cf_threads.numMessages += 1;

    if(cforum.currentUser && message.message.user_id == cforum.currentUser.user_id) {
      return;
    }

    cforum.cf_threads.showNewAlert();

    if(uconf('load_messages_via_js') != 'no') {
      var url = cforum.baseUrl +
            (cforum.currentForum ? cforum.currentForum.slug : 'all') +
            message.thread.slug;

      $.get(url).
        done(function(data) {
          $("#t" + message.thread.thread_id).replaceWith(data);

          if(uconf('sort_threads') == 'newest-first') {
            $("[data-js=threadlist]").prepend($("#t" + message.thread.thread_id));
          }

          cforum.cf_threads.newMessages.push(message.message.message_id);
          var m;

          for(var i = 0; i < cforum.cf_threads.newMessages.length; ++i) {
            m = $("#m" + cforum.cf_threads.newMessages[i]);
            if(!m.hasClass('new')) {
              m.addClass('new');
            }
          }
        });
    }

    cforum.updateFavicon();
  },

  initGlobal: function() {
    if(!cforum.currentForum) {
      $("#cf_thread_forum_id").on('change', function() {
        var val = $(this).val();

        for(var i = 0; i < cforum.forums.length; ++i) {
          if(cforum.forums[i].forum_id == val) {
            cforum.currentForum = cforum.forums[i];
            break;
          }
        }
      });
      $("#cf_thread_forum_id").trigger('change');
    }
  },

  initCursor: function() {
    var content = $("#message_input");
    var subj = $("#cf_thread_message_subject");
    var author = $("#cf_thread_message_author");

    cforum.cf_threads.setCursor(author, subj, content);
  },

  setCursor: function(author, subject, content) {
    if(!subject.val()) {
      setTimeout(function() { subject.focus(); }, 0);
    }
    else {
      if(cforum.currentUser) {
        setTimeout(function() { content.focus(); }, 0);
        cforum.cf_threads.setCursorInContent(content);
      }
      else {
        if(!author.val()) {
          setTimeout(function() { author.focus(); }, 0);
        }
        else {
          setTimeout(function() { content.focus(); }, 0);
          cforum.cf_threads.setCursorInContent(content);
        }
      }
    }
  },

  setCursorInContent: function(content) {
    var cnt = content.val();
    var i;

    for(i = 0; i < cnt.length; ++i) {
      if(cnt.substr(i, 1) == '>' &&
         (i === 0 || cnt.substr(i - 1, 1) == "\n") &&
         cnt.substr(i + 1, 1) == ' ') {
        content.setSelection(i, i);
        return;
      }
    }
  },

  initOpenClose: function() {
    $("#link-archiv").after(' <li id="open-close-all-threads" class="close-all"><a href="#">' + t('close_all_threads') + "</a></li>");
    $("div[data-js=threadlist] .thread > header").
      prepend("<i class=\"icon-thread open\"> </i>");

    $("div[data-js=threadlist] .thread > header > i").
      click(cforum.cf_threads.toggleThread);

    $("#open-close-all-threads").click(cforum.cf_threads.toggleAllThreads);

    if(hasLocalstorage()) {
      var has_open = false;

      $("div[data-js=threadlist] .thread").each(function() {
        var $this = $(this);
        var id = $this.attr('id');

        if(localStorage['closed-' + id]) {
          $this.children("ol").css('display', 'none');
          $this.find("header > i.icon-thread").
            removeClass("open").
            addClass('closed');
        }
        else {
          has_open = true;
        }
      });

      if(!has_open) {
        $("#open-close-all-threads a").text(t('open_all_threads'));
        $("#open-close-all-threads").
          removeClass("close-all").
          addClass("open-all");
      }
    }
  },

  toggleThread: function() {
    var $this = $(this);
    var elem = $this.closest("article");

    if($this.hasClass('open')) {
      $this.removeClass("open").addClass('closed');
      elem.children("ol").slideUp('fast');

      if(hasLocalstorage()) {
        localStorage['closed-' + elem.attr('id')] = true;
      }
    }
    else {
      $this.removeClass("closed").addClass('open');
      elem.children("ol").slideDown('fast');

      if(hasLocalstorage()) {
        localStorage.removeItem('closed-' + elem.attr('id'));
      }
    }
  },

  toggleAllThreads: function(ev) {
    ev.preventDefault();

    if($(this).hasClass('open-all')) {
      $("div[data-js=threadlist] .thread > ol").
        css('display', 'block');
      $("div[data-js=threadlist] .thread > header > i").
        addClass('open').
        removeClass("closed");

      $("#open-close-all-threads a").text(t('close_all_threads'));
      $("#open-close-all-threads").
        removeClass("open-all").
        addClass("close-all");

      if(hasLocalstorage()) {
        $("div[data-js=threadlist] .thread").each(function() {
          localStorage.removeItem('closed-' + $(this).attr('id'));
        });
      }
    }
    else {
      $("div[data-js=threadlist] .thread > ol").
        css('display', 'none');
      $("div[data-js=threadlist] .thread > header > i").
        addClass('closed').
        removeClass("open");

      $("#open-close-all-threads a").text(t('open_all_threads'));
      $("#open-close-all-threads").
        removeClass("close-all").
        addClass("open-all");

      if(hasLocalstorage()) {
        $("div[data-js=threadlist] .thread").each(function() {
          localStorage['closed-' + $(this).attr('id')] = true;
        });
      }
    }
  }
};

/* eof */
