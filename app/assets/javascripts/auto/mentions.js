/* -*- coding: utf-8 -*- */
/* global cforum, t */

cforum.replacements = function(elem, with_mentions) {
  var strategies = [];

  strategies.push({
    id: "smileys",
    match: /(:-?\)|;-?\)|:-?D|:-?P|:-?\(|:-?O|:-?\||:-?\/|:-?x|m\()$/i,
    index: 1,
    search: function(term, callback) {
      var found = [];

      term = term.toUpperCase();

      switch (term) {
        case ":-)":
        case ":)":
          found = ["😀"];
          break;
        case ";-)":
        case ";)":
          found = ["😉"];
          break;
        case ":-D":
        case ":D":
          found = ["😂"];
          break;
        case ":-P":
        case ":P":
          found = ["😝", "😛", "😜"];
          break;
        case ":-(":
        case ":(":
          found = ["😟"];
          break;
        case ":-O":
        case ":O":
          found = ["😱", "😨"];
          break;
        case ":-|":
        case ":|":
          found = ["😐", "😑"];
          break;
        case ":-/":
        case ":/":
          found = ["😕", "😏"];
          break;
        case "M(":
          found = ["🤦"];
          break;
        case ":-X":
        case ":X":
          found = ["😘", "😗", "😙", "😚"];
      }

      callback(found);
    },
    replace: function(text) {
      return text;
    }
  });

  strategies.push({
    id: "emoji",
    type: "row",
    rowLength: 5,
    match: function(pre) {
      if ($(elem).data("is-btn")) {
        $(elem).data("is-btn", false);
        return /$/;
      } else {
        return /\B:([:\-+\w]+)$/;
      }
    },
    index: 1,
    search: function(term, callback) {
      callback(
        $.map(Object.keys(cforum.emojis), function(emoji) {
          return term == ":" || emoji.indexOf(term) !== -1 ? emoji : null;
        })
      );
    },
    template: function(value) {
      return cforum.emojis[value];
    },
    replace: function(value) {
      return cforum.emojis[value];
    }
  });

  strategies.push({
    id: "typography",
    match: /(=>|<=|<=>|"|\.\.\.|\*|->|<-|-{1,3}|\^|\[tm\]?|=\/=?|=)$/,
    index: 1,
    search: function(term, callback) {
      var found = [];

      switch (term) {
        case '"':
          found = ['""', "„“", "‚‘"];
          break;
        case "...":
          found = ["…"];
          break;
        case "---":
          found = ["—"];
          break;
        case "--":
          found = ["–", "—"];
          break;
        case "-":
          found = ["−", "–", "—"];
          break;
        case "*":
          found = ["×"];
          break;
        case "->":
          found = ["→", "←", "↑", "↓"];
          break;
        case "<-":
          found = ["←", "→", "↑", "↓"];
          break;
        case "^":
          found = ["↑", "▲", "←", "→", "↓"];
          break;
        case "=>":
          found = ["⇒", "⇐", "⇔"];
          break;
        case "<=":
          found = ["⇐", "⇒", "⇔"];
          break;
        case "<=>":
          found = ["⇔", "⇐", "⇒"];
          break;
        case "[tm":
        case "[tm]":
          found = ["™"];
          break;
        case "=":
        case "=/":
        case "=/=":
          found = ["≠", "≈"];
          break;
      }

      callback(found);
    },
    replace: function(text) {
      switch (text) {
        case '""':
          return ['"', '"'];
        case "„“":
          return ["„", "“"];
        case "‚‘":
          return ["‚", "‘"];
      }

      return text;
    },
    template: function(value) {
      switch (value) {
        case "−":
          return value + " (" + t("replacements.minus_sign") + ")";
        case "–":
          return value + " (" + t("replacements.en_dash") + ")";
        case "—":
          return value + " (" + t("replacements.em_dash") + ")";

        default:
          return value;
      }
    }
  });

  if (with_mentions) {
    strategies.push({
      id: "mentions",
      match: /\B@([^\n@]{2,})$/,
      search: function(term, callback) {
        $.get(
          cforum.baseUrl + "users.json?nick=" + encodeURIComponent(term)
        ).done(function(data) {
          callback(
            $.map(data, function(element) {
              return element.username;
            })
          );
        });
      },
      index: 1,
      replace: function(mention) {
        return "@" + mention + " ";
      }
    });
  }

  $(elem)
    .textcomplete(strategies, { maxCount: 750 })
    .on("textComplete:render", function(ev, menu) {
      if (menu.attr("data-strategy") == "emoji") {
        menu.css("display", "flex");
      } else {
        menu.css("display", "block");
      }
    });
};

/* eof */
