cforum.tags = {
  views: {
    tag: "<li class=\"tag label label-info\" style=\"display:none\"><input name=\"tags[]\" type=\"hidden\" value=\"{{tag}}\"><i class=\"icon icon-trash del-tag\"> </i> {{tag}}</li>",
    tagSuggestion: "<li class=\"tag label label-info\" style=\"display:none\" data-tag=\"{{tag}}\"><i class=\"icon icon-ok del-tag\"> </i> {{tag}}</li>"
  },

  autocomplete_timeout: null,
  suggestionsTimeout: null,
  maxTags: 4,

  autocomplete: function() {
    cforum.tags.autocomplete_timeout = null;

    var $tag_input = $("#tags-input");

    if($tag_input.val().length >= 2) {
      $.get(
        cforum.baseUrl + '/' + cforum.currentForum.slug + '/tags.json',
        's=' + encodeURIComponent($tag_input.val()),
        function(data) {
          if(data.length > 0) {
            var val = $tag_input.val();
            var val_l = $.trim(val.toLowerCase());

            for(var i = 0; i < data.length; ++i) {
              if(val_l == data[i].tag_name.toLowerCase()) {
                return;
              }
            }

            var tag = data[0].tag_name;

            $tag_input.val(val + tag.substring(val.length));
            $tag_input.selection(val.length, tag.length);
          }
        }
      );

    }
  },

  suggestions: function(text) {
    var tokens = text.split(/[^a-z0-9äöüß-]+/i);
    var words = {};

    for(var i = 0; i < tokens.length; ++i) {
      if(tokens[i].match(/^[a-z0-9äöüß-]+$/i) && tokens[i].length > 2) {
        words[tokens[i].toLowerCase()] = 1;
      }
    }

    return Object.keys(words);
  },

  suggestTags: function() {
    var suggestions = cforum.tags.suggestions($("#cf_message_content").val());

    $.get(
      cforum.baseUrl + '/' + cforum.currentForum.slug + '/tags.json',
      'tags=' + encodeURIComponent(suggestions.join(",")),
      function(data) {
        var tag_list = $("#tags-suggestions");
        tag_list.html("");

        for(var i = 0; i < data.length && i < cforum.tags.maxTags; ++i) {
          cforum.tags.appendTag(data[i].tag_name, tag_list, cforum.tags.views.tagSuggestion);
        }

      }
    )
  },

  addTagSuggestion: function(ev) {
    ev.preventDefault();
    var tag = $(ev.target).closest("li").attr("data-tag");
    var hasIt = false;

    if($("#tags-list .tag").length >= cforum.maxTags) {
      return;
    }

    $("#tags-list input[type=hidden]").each(function() {
      if($(this).val() == tag) {
        hasIt = true;
      }
    });

    if(!hasIt) {
      cforum.tags.appendTag(tag);
    }
  },

  addTag: function(ev) {
    ev.preventDefault();
    var $this = $(this);

    if($.trim($this.val()) && $this.val() != ',' && $("#tags-list .tag").length < cforum.maxTags) {
      var val = $.trim($this.val().replace(/[, ].*/, '').toLowerCase());
      cforum.tags.appendTag(val);

      v = $this.val();
      $this.val(v.indexOf(String.fromCharCode(ev.keyCode)) == -1 ? '' : v.replace(/.*[, ]?/, ''));
    }

  },

  appendTag: function(tag, list, view) {
    if(!list) {
      list = $("#tags-list");
    }

    if(!view) {
      view = cforum.tags.views.tag;
    }

    list.append(Mustache.render(view, {tag: tag}));
    list.find(".tag").last().fadeIn('fast');
  },

  removeTag: function(ev) {
    var $this = $(ev.target);

    if($this.hasClass('del-tag')) {
      ev.preventDefault();
      $this.closest("li.tag").fadeOut('fast', function() { $(this).remove(); });
    }
  },

  initTags: function() {
    tags = $("#tags-input").val().split(",").map(function(x) {return $.trim(x);}).filter(function(x) {
      if(x) {
        return true;
      }

      return false;
    });

    cforum.tags.suggestTags();
    for(var i = 0; i < tags.length; ++i) {
      cforum.tags.appendTag(tags[i]);
    }

    $("#tags-input").val("");

    $("#tags-input").on('keyup', cforum.tags.handleTagsKeyUp);
    $("#tags-input").on('focusout', cforum.tags.addTag);
    $("#tags-list").on('click', cforum.tags.removeTag);

    $("#cf_message_content").on('keyup', cforum.tags.handleSuggestionsKeyUp);
    $("#tags-suggestions").on('click', cforum.tags.addTagSuggestion);
  },

  handleSuggestionsKeyUp: function() {
    // cforum.tags.suggestTags
    if(cforum.tags.suggestionsTimeout) {
      window.clearTimeout(cforum.tags.suggestionsTimeout);
    }

    cforum.tags.suggestionsTimeout = window.setTimeout(cforum.tags.suggestTags, 800);
  },

  handleTagsKeyUp: function(ev) {
    if(cforum.tags.autocomplete_timeout) {
      window.clearTimeout(cforum.tags.autocomplete_timeout);
    }

    if(ev.keyCode == 188 || ev.keyCode == 32) {
      cforum.tags.addTag.call($("#tags-input"), ev);
    }
    else {
      cforum.tags.autocomplete_timeout = window.setTimeout(cforum.tags.autocomplete, 800);
    }
  }
};


/* eof */
