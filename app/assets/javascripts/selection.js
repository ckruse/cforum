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

  var getSelection = function(e) {
    return (
      ('selectionStart' in e && function() {
        var l = e.selectionEnd - e.selectionStart;
        return { start: e.selectionStart, end: e.selectionEnd, length: l, text: e.value.substr(e.selectionStart, l) };
      }) ||
        /* browser not supported */
      function() {
        return null;
      }
    )();
  };

  var setSelection = function(e, start, end) {
    return (
      ('selectionStart' in e && function() {
        e.selectionStart = start;
        e.selectionEnd = end;
        return;
      }) ||
        /* browser not supported */
      function() {
        return null;
      }
    )();
  };

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
        var sel = getSelection(this);
        replaceSelection(this, "\t");
        setSelection(this, sel.start+1, sel.end+1);
      }
    });
  };
})(jQuery);

/* eof */
