/* -*- coding: utf-8 -*- */
/* global cforum */

cforum.mentions = function(elem) {
  $(elem).textcomplete([
    {
      id: 'mentions',
      match: /\B@([^\n]{2,})$/,
      search: function (term, callback) {
        $.get(cforum.baseUrl + 'users.json?nick=' + encodeURIComponent(term)).
          done(function(data) {
            callback($.map(data, function(element) { return element.username; }));
          });
      },
      index: 1,
      replace: function (mention) {
        return '@' + mention + ' ';
      }
    },

    {
      id: 'typography',
      match: /(=>|<=|<=>|,,|...|\*|->|<-|-{1,3}|\^|\[tm\]?|=\/=?|=)/,
      search: function (term, callback) {
        var found = [];

        switch(term) {
        case ',,':
          found = ['„“', '‚‘'];
          break;
        case '...':
          found = ['…'];
          break;
        case '---':
          found = ['—'];
          break;
        case '--':
          found = ['–', '—'];
          break;
        case '-':
          found = ['−', '–', '—'];
          break;
        case '*':
          found = ['×'];
          break;
        case '->':
          found = ['→', '←', '↑', '↓'];
          break;
        case '<-':
          found = ['←', '→', '↑', '↓'];
          break;
        case '^':
          found = ['↑', '▲', '←', '→', '↓'];
          break;
        case '=>':
          found = ['⇒', '⇐', '⇔'];
          break;
        case '<=':
          found = ['⇐', '⇒', '⇔'];
          break;
        case '<=>':
          found = ['⇔', '⇐', '⇒'];
          break;
        case '[tm':
        case '[tm]':
          found = ['™'];
          break;
        case '=':
        case '=/':
        case '=/=':
          found = ['≠','≈'];
          break;
        }

        callback(found);
      },
      index: 1,
      replace: function(text) { return text; }
    },

    {
      id: 'emoji',
      type: 'row',
      rowLength: 5,
      match: /\B:([\-+\w]*)$/,
      search: function(term, callback) {
        callback($.map(Object.keys(cforum.emojis), function(emoji) {
          return emoji.indexOf(term) !== false ? emoji : null;
        }));
      },
      template: function(value) {
        return cforum.emojis[value];
      },
      replace: function (value) {
        return cforum.emojis[value];
      },
      index: 1
    }
  ], { maxCount: 750 })
    .on("textComplete:render", function(ev, menu) {
      if(menu.attr("data-strategy") == "emoji") {
        menu.css("display", "flex");
      }
      else {
        menu.css("display", "block");
      }
    });
};

/* eof */
