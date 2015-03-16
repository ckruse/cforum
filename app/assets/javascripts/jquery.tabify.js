/* -*- coding: utf-8 -*- */

(function($) {
  $.fn.tabEnable = function() {
    this.on('keydown', function(event) {
      var insertTab = false;

      if('key' in event && (event.key == "1" || event.key == "¡") && event.altKey) {
        insertTab = true;
      }
      else if(event.keyCode == 49 && event.ctrlKey) {
        insertTab = true;
      }

      if(insertTab) {
        event.preventDefault();

        var $this = $(this);
        var sel = $this.getSelection();
        $this.replaceSelection("\t");
        $this.setSelection(sel.start+1, sel.end+1);
      }
    });
  };
})(jQuery);

/* eof */
