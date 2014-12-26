/* -*- coding: utf-8 -*- */

(function($) {
  $.fn.setCursorPosition = function(pos) {
    var node = this.get(0);
    if(node.setSelectionRange) {
      node.setSelectionRange(pos, pos);
    }
    else if(node.createTextRange) {
      var range = node.createTextRange();
      range.collapse = true;

      if(pos < 0) {
        pos = this.val().length + pos;
      }

      range.moveEnd('character', pos);
      range.moveStart('character', pos);
      range.select();
    }
  };
})(jQuery);
