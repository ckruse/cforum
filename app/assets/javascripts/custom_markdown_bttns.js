/* -*- coding: utf-8 -*- */

cforum.markdown_buttons = {
  hellip: {
    name: 'cmdHellips',
    toggle: false,
    title: "Horizontale Ellipse",
    btnText: "…",
    callback: function(e) {
      var cursor, selected = e.getSelection();

      e.replaceSelection("…");
      cursor = selected.start;

      e.setSelection(cursor, cursor + 1);
    }
  },

  mdash: {
    name: 'cmdMdash',
    toggle: false,
    title: "Gedankenstrich",
    btnText: "–",
    callback: function(e) {
      var cursor, selected = e.getSelection();

      e.replaceSelection("–");
      cursor = selected.start;

      e.setSelection(cursor, cursor + 1);
    }
  },

  almostEqualTo: {
    name: 'cmdAlmostEqualTo',
    toggle: false,
    title: "ungefähr gleich/circa",
    btnText: "≈",
    callback: function(e) {
      var cursor, selected = e.getSelection();

      e.replaceSelection("≈");
      cursor = selected.start;

      e.setSelection(cursor, cursor + 1);
    }
  },

  unequal: {
    name: 'cmdUnequal',
    toggle: false,
    title: "ungleich",
    btnText: "≠",
    callback: function(e) {
      var cursor, selected = e.getSelection();

      e.replaceSelection("≠");
      cursor = selected.start;

      e.setSelection(cursor, cursor + 1);
    }
  },

  times: {
    name: 'cmdTimes',
    toggle: false,
    title: "× (mal)",
    btnText: "×",
    callback: function(e) {
      var cursor, selected = e.getSelection();

      e.replaceSelection("×");
      cursor = selected.start;

      e.setSelection(cursor, cursor + 1);
    }
  },

  arrowRight: {
    name: 'cmdArrowRight',
    toggle: false,
    title: "Pfeil nach rechts einfügen",
    btnText: "→",
    callback: function(e) {
      var cursor, selected = e.getSelection();

      e.replaceSelection("→");
      cursor = selected.start;

      e.setSelection(cursor, cursor + 1);
    }
  },

  arrowUp: {
    name: 'cmdArrowUp',
    toggle: false,
    title: "Pfeil nach oben einfügen",
    btnText: "↑",
    callback: function(e) {
      var cursor, selected = e.getSelection();

      e.replaceSelection("↑");
      cursor = selected.start;

      e.setSelection(cursor, cursor + 1);
    }
  },

  blackUpPointingTriangle: {
    name: 'cmdBlackUpPointingTriangle',
    toggle: false,
    title: "▲ einfügen",
    btnText: "▲",
    callback: function(e) {
      var cursor, selected = e.getSelection();

      e.replaceSelection("▲");
      cursor = selected.start;

      e.setSelection(cursor, cursor + 1);
    }
  },

  rightwardsDoubleArrow: {
    name: 'cmdRightwardsDoubleArrow',
    toggle: false,
    title: "⇒ einfügen",
    btnText: "⇒",
    callback: function(e) {
      var cursor, selected = e.getSelection();

      e.replaceSelection("⇒");
      cursor = selected.start;

      e.setSelection(cursor, cursor + 1);
    }
  },

  trademark: {
    name: 'cmdTrademark',
    toggle: false,
    title: "™ einfügen",
    btnText: "™",
    callback: function(e) {
      var cursor, selected = e.getSelection();

      e.replaceSelection("™");
      cursor = selected.start;

      e.setSelection(cursor, cursor + 1);
    }
  },

  doublePunctuationMarks: {
    name: 'cmdDoublePunctuationMarks',
    title: "„“ einfügen",
    btnText: "„“",
    callback: function(e) {
      var chunk = "", cursor, selected = e.getSelection(), content = e.getContent();

      if(selected.length !== 0) {
        chunk = selected.text;
      }

      if(content.substr(selected.start-1,1) === '„' && content.substr(selected.end,1) === '“' ) {
        e.setSelection(selected.start - 1,selected.end + 1);
        e.replaceSelection(chunk);
        cursor = selected.start - 1;
      }
      else {
        e.replaceSelection("„" + chunk + "“");
        cursor = selected.start + 1;
      }

      e.setSelection(cursor, cursor + chunk.length);
    }
  },

  singlePunctuationMarks: {
    name: 'cmdSingleePunctuationMarks',
    title: "‚‘ einfügen",
    btnText: "‚‘",
    callback: function(e) {
      var chunk = "", cursor, selected = e.getSelection(), content = e.getContent();

      if(selected.length !== 0) {
        chunk = selected.text;
      }

      if(content.substr(selected.start-1,1) === '‚' && content.substr(selected.end,1) === '‘' ) {
        e.setSelection(selected.start - 1,selected.end + 1);
        e.replaceSelection(chunk);
        cursor = selected.start - 1;
      }
      else {
        e.replaceSelection("‚" + chunk + "‘");
        cursor = selected.start + 1;
      }

      e.setSelection(cursor, cursor + chunk.length);
    }
  }
};

/* eof */
