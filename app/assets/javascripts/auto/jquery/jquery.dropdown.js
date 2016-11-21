/* coding: utf-8 */

(function($) {
  $.fn.dropdown = function() {
    var $this = $(this);

    var anchor = $this.find('.anchor');

    anchor.addClass('visible');
    anchor.attr("tabindex", 0);
    $this.addClass('js');
    var parent = anchor.parent();

    anchor.on('click', function(ev) {
      ev.preventDefault();
      parent.toggleClass('open');
    });
  };
})(jQuery);

/* eof */
