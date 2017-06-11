/* coding: utf-8 */

(function($) {
  $.fn.dropdown = function() {
    var mql = window.matchMedia("only screen and (min-width: 35em)");
    if(!mql.matches) {
      return;
    }

    var $this = $(this);
    var anchor = $this.find('.anchor');
    var text = anchor
        .text()
        .replace(/&/, '&amp;')
        .replace(/</, '&lt;')
        .replace(/>/, '&gt;');

    anchor.html('<button type="button" aria-haspopup="true" aria-expanded="false">' + text + '</button>');
    var menuButton = anchor.find('button');

    anchor.addClass('visible');
    $this.addClass('js');

    var parent = anchor.parent();
    var openMenu = function(element) {
      if(!element.hasClass('open')) {
        element.addClass('open');
        menuButton.attr('aria-expanded', 'true');
        menuButton.focus();
      }
    };

    var hideMenu = function(element) {
      element.removeClass('open');
      menuButton.attr('aria-expanded', 'false');
    };

    var toggleMenu = function(element) {
      if(element.hasClass('open')) {
        hideMenu(element);
      }
      else {
        openMenu(element);
      }
    };

    $this.on('keypress', function(ev) {
      if(ev.keyCode == 27) {
        ev.preventDefault();
        hideMenu(parent);
        menuButton.focus();
      }
    });

    menuButton.on('click', function(ev) {
      ev.preventDefault();
      toggleMenu(parent);
    });

    $this.find("a, button").on('blur', function() {
      window.setTimeout(function() {
        var focused = $this.find(":focus");
        if(focused.length === 0) {
          hideMenu(parent);
        }
      }, 200);
    });

    $this.on('keydown', function(ev) {
      if(ev.keyCode != 40 && ev.keyCode != 38) {
        return;
      }

      ev.preventDefault();
      ev.stopPropagation();

      openMenu(parent);


      var links = $this.find("li");
      var direction = ev.keyCode == 40 ? 1 : -1;

      for(var i = 0; i < links.length; ++i) {
        var n = $(links[i]).find("a:first-of-type");
        if(n.is(":focus")) {
          if(i + direction == links.length) {
            $(links[0]).find("a:first-of-type").focus();
          }
          else if(i + direction == -1) {
            $(links[links.length - 1]).find("a:first-of-type").focus();
          }
          else {
            $(links[i + direction]).find("a:first-of-type").focus();
          }

          return;
        }
      }

      $(links[0]).find("a:first-of-type").focus();
    });
  };
})(jQuery);

/* eof */
