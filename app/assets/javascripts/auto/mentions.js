/* -*- coding: utf-8 -*- */
/* global cforum */

(function($) {
  $.fn.mentions = function() {
    var area = this;
    var tm = null;
    var elem = $("<ul class=\"mentions-complete\" style=\"display:none\"></ul>");
    var completed = {};

    $("body").append(elem);

    var hideElem = function() {
      elem.fadeOut('fast', function() { elem.html(''); });
    };

    elem.on('keydown', function(ev) {
      ev.preventDefault();

      switch(ev.keyCode) {
      case 40:
        $(ev.target).next().focus();
        return;
      case 38:
        $(ev.target).prev().focus();
        return;

      case 32:
      case 13:
      case 9:
        chooseName(ev);
      }

      hideElem();
      area.focus();
    });

    area.on('keydown', function(ev) {
      if(elem.is(":visible")) {
        if(ev.keyCode == 9 || ev.keyCode == 40 || ev.keyCode == 38 || ev.keyCode == 27) {
          ev.preventDefault();
        }

        switch(ev.keyCode) {
        case 9:
          elem.find('li:first').focus();
          chooseName(ev);
          break;

        case 40:
          elem.find('li:first').focus();
          break;

        case 39:
          elem.find('li:last').focus();
          break;

        case 27:
          hideElem();
          break;
        }

      }
    });

    var showAutocomplete = function(nick) {
      $.get(cforum.baseUrl + 'users.json?nick=' + encodeURIComponent(nick)).
        done(function(data) {
          if(data.length === 0 || (data.length == 1 && data[0].username == nick)) {
            hideElem();
            return;
          }

          var pos = area.offset();
          var sel = area.getSelection();

          var caretPos = window.getCaretCoordinates(area.get(0), sel.end);

          var html = "";
          for(var i = 0; i < data.length && i < 20; ++i) {
            html += "<li tabindex=\"0\">" + data[i].username + "</li>";
          }

          elem.html(html);
          elem.css({
            position: 'absolute',
            left: (pos.left + caretPos.left - 20) + "px",
            top: (pos.top + caretPos.top + 10) + "px"
          });
          elem.fadeIn('fast');
        });
    };

    var isWordCharacter = function(chr) {
      return chr.match(/^[a-zäöüß0-9_.@-]/i);
    };

    var getAtText = function(callback, cb1) {
      var i, text = area.val(), c;
      var sel = area.getSelection();

      for(i = sel.start - 1; i >= 0 && text.substr(i, 1) != "\n"; --i) {
        c = text.substr(i, 1);
        if(c == '@' && (i == 0 || !isWordCharacter(text.substr(i - 1, 1))) ) {
          var nick = text.substr(i+1, sel.start - i).replace(/^\s+|\s+$/, '');
          if(nick) {
            callback(nick, i + 1, sel.start - i);
          }
          else if(cb1) {
            cb1();
          }
          return;
        }
      }

      if(cb1) {
        cb1();
      }
    };

    var chooseName = function(event) {
      var trg = $(event.target);
      if(!trg.is("li")) {
        return;
      }

      var name = trg.text();

      getAtText(function(text, start, len) {
        area.setSelection(start, start + len - 1);
        area.replaceSelection(name);
        area.setSelection(start + name.length, start + name.length);

        completed[start] = name;

        hideElem();
      });
    };

    elem.on('click', chooseName);

    this.on('keyup', function() {
      getAtText(function(nick, start) {
        if(tm) {
          window.clearTimeout(tm);
          tm = null;
        }

        if(completed[start] == nick) {
          return;
        }

        tm = window.setTimeout(function() { showAutocomplete(nick); }, 800);
      }, function() {
        if(tm) {
          window.clearTimeout(tm);
          tm = null;
        }

        hideElem();
      });
    });
  };
})(jQuery);

/* eof */
