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
      id: 'emoji',
      match: /\B:([\-+\w]*)$/,
      search: function(term, callback) {
        callback($.map(Object.keys(cforum.emojis), function(emoji) {
          return emoji.indexOf(term) === 0 ? emoji : null;
        }));
      },
      template: function(value) {
        return cforum.emojis[value] + " " + value;
      },
      replace: function (value) {
        return cforum.emojis[value];
      },
      index: 1
    }
  ]);
};

/* eof */
