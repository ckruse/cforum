/* -*- coding: utf-8 -*- */

(function($) {
  var replaceSelection = function(e, text) {
    return (
      ('selectionStart' in e && function() {
        e.value = e.value.substr(0, e.selectionStart) + text + e.value.substr(e.selectionEnd, e.value.length);
        // Set cursor to the last replacement end
        e.selectionStart = e.value.length;
        return this;
      }) ||
        /* browser not supported */
      function() {
        e.value += text;
        return jQuery(e);
      }
    )();
  };

  $.fn.tabEnable = function() {
    this.on('keydown', function(event) {
      var insertTab = false;

      if('key' in event && event.key && event.key == "@" && event.ctrlKey) {
        insertTab = true;
      }
      else if(event.keyCode == 50 && event.ctrlKey) {
        insertTab = true;
      }

      if(insertTab) {
        event.preventDefault();
        replaceSelection(this, "\t");
      }
    });
  };
})(jQuery);

/* eof */
