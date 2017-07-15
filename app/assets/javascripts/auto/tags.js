/* -*- coding: utf-8 -*- */
/* global cforum, Mustache, t */

cforum.tags = {
  maxTagCompletes: 15,
  events: $({}),
  views: {
    tag: "<li class=\"cf-tag\" style=\"display:none\"><input name=\"tags[]\" type=\"hidden\" value=\"{{tag}}\"><i class=\"icon-del-tag del-tag\"> </i> {{tag}}</li>",
    tagSuggestion: "<li class=\"cf-tag pointer\" style=\"display:none\" data-tag=\"{{tag}}\"><i class=\"icon-tag-ok del-tag\"> </i> {{tag}}</li>"
  },

  suggestionsTimeout: null,
  maxTags: 4,
  allTags: [],

  handleSuggestionsKeyUp: function() {
    if(cforum.tags.suggestionsTimeout) {
      window.clearTimeout(cforum.tags.suggestionsTimeout);
    }

    cforum.tags.suggestionsTimeout = window.setTimeout(cforum.tags.suggestTags, 1500);
  },

  suggestions: function(text) {
    var tokens = text.split(/[^a-z0-9äöüß-]+/i);
    var words = {};

    for(var i = 0; i < tokens.length; ++i) {
      if(tokens[i].match(/^[a-z0-9äöüß-]+$/i)) {
        words[tokens[i].toLowerCase()] = 1;
      }
    }

    return Object.keys(words);
  },

  removeLinks: function(txt) {
    txt = txt.replace(/^([\s\t]*)([\*\-\+]|\d\.)\s+/gm, '$1')
      .replace(/<(.*?)>/g, '$1')
      .replace(/^[=\-]{2,}\s*$/g, '')
      .replace(/\[\^.+?\](\: .*?$)?/g, '')
      .replace(/\s{0,2}\[.*?\]: .*?$/g, '')
      .replace(/\!\[.*?\][\[\(].*?[\]\)]/g, '')
      .replace(/\[(.*?)\][\[\(].*?[\]\)]/g, '$1')
      .replace(/^\s{1,2}\[(.*?)\]: (\S+)( ".*?")?\s*$/g, '')
      .replace(/^\#{1,6}\s*/g, '')
      .replace(/([\*_]{1,2})(\S.*?\S)\1/g, '$2')
      .replace(/(`{3,})(.*?)\1/gm, '$2')
      .replace(/^-{3,}\s*$/g, '')
      .replace(/`(.+)`/g, '$1')
      .replace(/\n{2,}/g, '\n\n')
      .replace(/^-- \n(.*)/m, '');

    return txt;
  },

  getTags: function(cb) {
    $.get(cforum.baseUrl + cforum.currentForum.slug + '/tags/suggestions.json')
      .done(function(data) {
        if(!data) {
          return;
        }

        cforum.tags.allTags = data;

        if(cb) {
          cb();
        }
      });
  },

  tagMatches: function(tag, suggestions) {
    var i;

    tag = tag.toLowerCase();

    for(i = 0; i < suggestions.length; ++i) {
      if(tag.match(new RegExp('^' + suggestions[i]))) {
        return true;
      }
    }

    return false;
  },

  suggestTags: function(recursing) {
    var node = $("#message_input");
    var mcnt;

    if(node.val()) {
      mcnt = node.val();
    }
    else {
      mcnt = node.text();
    }

    if(!mcnt) {
      return;
    }

    mcnt = cforum.tags.removeLinks(mcnt);

    var suggestions = cforum.tags.suggestions(mcnt);

    if(!cforum.tags.allTags) {
      if(!recursing) {
        cforum.tags.getTags(function() { cforum.tags.suggestTags(true); });
      }

      return;
    }

    var tag_list = $("#tags-suggestions");
    var tags_set = false;
    tag_list.find('li:not(.no-data)').remove();

    var data = cforum.tags.allTags;
    var found = 0;

    for(var i = 0; i < data.length && found < 3; ++i) {
      if(cforum.tags.tagMatches(data[i].tag, suggestions) && !cforum.tags.hasTag(data[i].tag)) {
        found += 1;
        cforum.tags.appendTag(data[i].tag, tag_list,
                              cforum.tags.views.tagSuggestion);
      }
    }

    if(found == 0) {
      tag_list.find('li.no-data').fadeIn('fast');
    }
    else {
      tag_list.find('li.no-data').css('display', 'none');
    }
  },

  addTagSuggestion: function(ev) {
    ev.preventDefault();
    var trg = $(ev.target).closest("li");
    var tag = trg.attr("data-tag");

    if($("#tags-list .cf-tag").length >= cforum.tags.maxTags) {
      return;
    }

    if(!cforum.tags.hasTag(tag)) {
      cforum.tags.appendTag(tag);
      cforum.tags.events.trigger('tags:add-tag', [tag]);
      trg.fadeOut('fast');
    }
  },

  showSuggestion: function(tag) {
    $("#tags-suggestions li").each(function() {
      var $this = $(this);
      var nam = $this.attr('data-tag');

      if(nam == tag && !$this.is(":visible")) {
        $this.fadeIn('fast');
      }
    });
  },

  hasTag: function(name) {
    var tags = $("#tags-list input[type=hidden]");

    name = name.toLowerCase();

    for(var i = 0; i < tags.length; ++i) {
      if($(tags[i]).val().toLowerCase() == name) {
        return true;
      }
    }

    return false;
  },

  addTag: function(ev) {
    ev.preventDefault();
    var $this = $(this);

    if($.trim($this.val()) && $this.val() != ',' && $("#tags-list .cf-tag").length < cforum.tags.maxTags) {
      var val = $.trim($this.val().replace(/,.*/, '').toLowerCase());

      if(!cforum.tags.hasTag(val)) {
        cforum.tags.appendTag(val, null, null, true);
        cforum.tags.events.trigger('tags:add-tag', val);
      }
    }

  },

  appendTag: function(tag, list, view, hidden) {
    if(!list) {
      list = $("#tags-list");
    }

    if(!view) {
      view = cforum.tags.views.tag;
    }

    list.append(Mustache.render(view, {tag: tag}));
    if(!hidden) {
      list.find(".cf-tag").last().fadeIn('fast');
    }

    $("#tags-list .no-data").fadeOut('fast');
  },

  removeTag: function(ev) {
    var $this = $(ev.target);
    var tag = $this.parent().find('input').val();

    if($this.hasClass('del-tag')) {
      cforum.tags.showSuggestion(tag);
      ev.preventDefault();

      $this.closest("li.cf-tag").fadeOut('fast', function() {
        $(this).remove();
        $("#replaced_tag_input").closest('.cf-cgroup').fadeIn('fast');
        $("#replaced_tag_input").focus();
        cforum.tags.events.trigger('tags:remove', tag);

        if($("#tags-list").find(".cf-tag").length === 0) {
          $("#tags-list .no-data").fadeIn('fast');
        }
      });
    }
  },

  initTags: function() {
    var el = $("#tags-input");

    if(el.length == 0) {
      return;
    }

    var tags = el.val().split(",").map(function(x) { return $.trim(x); }).filter(function(x) {
      if(x) {
        return true;
      }

      return false;
    });

    cforum.tags.suggestTags();
    for(var i = 0; i < tags.length; ++i) {
      cforum.tags.appendTag(tags[i]);
    }

    $("<input type=\"text\" id=\"replaced_tag_input\" class=\"tags-input\">").insertBefore(el);
    el.remove();
    el = $("#replaced_tag_input");

    if(tags.length >= cforum.tags.maxTags) {
      el.closest('.cf-cgroup').css('display', 'none');
    }

    el.on('keyup', cforum.tags.handleTagsKeyUp);
    el.on('focusout', cforum.tags.addTag);
    $("#tags-list").on('click', cforum.tags.removeTag);
    $("#message_input").on('input', cforum.tags.handleSuggestionsKeyUp);
    $("#tags-suggestions").on('click', cforum.tags.addTagSuggestion);
    $("#cf_thread_forum_id").on('change', function() {
      cforum.tags.getTags(cforum.tags.suggestTags);
    });

    if(cforum.tags.allTags.length === 0) {
      cforum.tags.getTags(cforum.tags.setupAutocomplete);
    }
    else {
      cforum.tags.setupAutocomplete();
    }

    cforum.tags.events.on('tags:add-tag', cforum.tags.checkForInvalidTag);
    cforum.tags.events.on('tags:remove', cforum.tags.hideInvalidWarnings);
  },

  autocompleteFilter: function(term, exact) {
    var tags = cforum.tags.allTags;
    var found = [];
    var i;

    if(term === "") {
      for(i = 0; i < cforum.tags.maxTagCompletes; ++i) {
        found.push(tags[i].tag);
      }
      return found;
    }

    term = term.toLowerCase();

    var rx;
    if(exact) {
      rx = new RegExp('^' + term + '$');
    }
    else {
      rx = new RegExp('^' + term);
    }

    for(i = 0; i < tags.length && found.length <= cforum.tags.maxTagCompletes; ++i) {
      if(tags[i].tag.match(rx)) {
        found.push(tags[i].tag);
      }
    }

    return found;
  },

  setupAutocomplete: function() {
    var el = $("#replaced_tag_input");

    el.autocomplete({
      source: function(request, response) {
        response(cforum.tags.autocompleteFilter(request.term));
      },
      minLength: 0,
      select: function(event, ui) {
        $("#replaced_tag_input").val(ui.item.label);
        cforum.tags.addTag.call($("#replaced_tag_input"), event);
      },
      response: function(event, ui) {
        if(ui.content.length == 1 && !cforum.tags.mayCreateTag(cforum.currentUser)) {
          var tag = ui.content[0].label;
          ui.content = [];

          cforum.tags.appendTag(tag, null, null, true);
          cforum.tags.events.trigger('tags:add-tag', tag);
        }
      }
    });

    el.on('focus', function() {
      el.autocomplete("search", "");
    });

  },

  handleTagsKeyUp: function(ev) {
    if(ev.keyCode == 188) {
      cforum.tags.addTag.call($("#replaced_tag_input"), ev);
    }
  },

  checkForInvalidTag: function(event, tag) {
    var data = cforum.tags.autocompleteFilter(tag, true);
    var show = true;

    if(typeof data == 'object') {
      if(data.length === 0) {
        var el = $("#tags-group").closest(".cf-cgroup").find(".errors");

        if(el.length === 0) {
          $("#tags-group").
            closest(".cf-cgroup").append("<div class=\"errors\"></div>");
          el = $("#tags-group").closest(".cf-cgroup").find(".errors");
        }

        var text = '';
        var clss = '';
        if(cforum.tags.mayCreateTag(cforum.currentUser)) {
          text = t('tags.tag_will_be_created');
          clss = 'cf-warning';
        }
        else {
          var last = $("#tags-list").find('.cf-tag:last');

          text = t('tags.tag_doesnt_exist');
          clss = 'cf-error';
          show = false;

          if(!last.is(":visible")) {
            last.remove();
          }
        }

        var divs = el.find("div");
        if(divs.length > 0) {
          divs.fadeOut("fast", function() {
            el.html("<div class=\"cf-alert " + clss + "\" style=\"display:none\">" + text + "</div>");
            el.find("div").fadeIn("fast");
          });
        }
        else {
          el.html("<div class=\"cf-alert " + clss + "\" style=\"display:none\">" + text + "</div>");
          el.find("div").fadeIn("fast");
        }

        window.setTimeout(cforum.tags.hideInvalidWarnings, 3000);
      }
      else {
        cforum.tags.hideInvalidWarnings();
      }
    }

    if(show) {
      var $this = $("#replaced_tag_input");
      var v = $this.val();
      $this.val(v.replace(/.*,?/, ''));

      $("#tags-list").find('.cf-tag:last').fadeIn('fast');

      if($("#tags-list").find('.cf-tag').length >= cforum.tags.maxTags) {
        $("#replaced_tag_input").closest('.cf-cgroup').fadeOut('fast');
      }
    }
  },

  hideInvalidWarnings: function(ev, tag) {
    $("#tags-group").
      closest(".cf-cgroup").
      find(".errors div").
      fadeOut("fast", function() { $(this).remove(); });
  },

  mayCreateTag: function(user) {
    if(!user) {
      return false;
    }

    if(user.admin) {
      return true;
    }

    if(user.badges) {
      for(var i = 0; i < user.badges.length; ++i) {
        var b = user.badges[i];

        switch(b.badge_type) {
        case 'create_tag':
        case 'create_tag_synonym':
          return true;
        }
      }
    }

    return false;
  }
};


/* eof */
