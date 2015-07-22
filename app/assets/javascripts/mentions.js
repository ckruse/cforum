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
      area.removeAttr('tabindex');
      elem.fadeOut('fast', function() { elem.html(''); });
    };

    elem.on('keydown', function(ev) {
      /* we completely ignore the tabkey */
      if(ev.keyCode == 9) {
        return;
      }

      ev.preventDefault();

      if(ev.keyCode == 32 || ev.keyCode == 13) {
        chooseName(ev);
      }

      hideElem();
      area.focus();
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

          area.attr('tabindex', 1);

          var caretPos = window.getCaretCoordinates(area.get(0), sel.end);

          var html = "";
          for(var i = 0; i < data.length && i < 20; ++i) {
            html += "<li tabindex=\"" + (i + 2) + "\">" + data[i].username + "</li>";
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

    var getAtText = function(callback, cb1) {
      var i, text = area.val(), c;
      var sel = area.getSelection();

      for(i = sel.start - 1; i >= 0 && text.substr(i, 1) != "\n"; --i) {
        c = text.substr(i, 1);
        if(c == '@') {
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
        area.setSelection(start - 1, start + name.length);

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
