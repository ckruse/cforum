/* coding: utf-8 */

(function($) {
  $.fn.dropdown = function() {
    var $this = $(this);

    var anchor = $this.find('.anchor');

    anchor.addClass('visible');
    anchor.attr("tabindex", '0');
    $this.addClass('js');
    var parent = anchor.parent();

    anchor.on('focus', function() {
      parent.addClass('open');
    });

    anchor.on('keypress', function(ev) {
      if(ev.which == 32 || ev.which == 13) {
        ev.preventDefault();
        parent.toggleClass('open');
      }
    });

    anchor.on('click', function(ev) {
      ev.preventDefault();
      parent.toggleClass('open');
    });

    $this.on('keydown', function(ev) {
      if(ev.keyCode != 40 && ev.keyCode != 38) {
        return;
      }

      ev.preventDefault();
      ev.stopPropagation();

      if(!$this.hasClass('open')) {
        $this.addClass('open');
      }


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
