/* coding: utf-8 */

(function($) {
  $.fn.dropdown = function() {
    var $this = $(this);

    var anchor = $this.find('.anchor');
    var menu = $this.find(".menu");

    anchor.addClass('visible');
    $this.addClass('js');
    var parent = anchor.parent();

    anchor.on('click', function(ev) {
      ev.preventDefault();
      parent.toggleClass('open');

      if(!parent.hasClass("open")) {
        parent.blur();
      }
    });

    parent.on('blur', function() { parent.removeClass('open'); });
  };
})(jQuery);

/* eof */
