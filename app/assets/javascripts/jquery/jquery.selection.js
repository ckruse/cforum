/* -*- coding: utf-8 -*- */

(function($) {
  $.fn.replaceSelection = function(text) {
    var node = this.get(0);

    return (
      ('selectionStart' in node && function() {
        node.value = node.value.substr(0, node.selectionStart) + text + node.value.substr(node.selectionEnd, node.value.length);
        // Set cursor to the last replacement end
        node.selectionStart = node.value.length;
        return this;
      }) ||
        /* browser not supported */
      function() {
        node.value += text;
        return this;
      }
    )();
  };

  $.fn.getSelection = function() {
    var node = this.get(0);

    return (
      ('selectionStart' in node && function() {
        var l = node.selectionEnd - node.selectionStart;
        return { start: node.selectionStart, end: node.selectionEnd, length: l, text: node.value.substr(node.selectionStart, l) };
      }) ||
        /* browser not supported */
      function() {
        return null;
      }
    )();
  };

  $.fn.setSelection = function(start, end) {
    var node = this.get(0);

    return (
      ('selectionStart' in node && function() {
        node.selectionStart = start;
        node.selectionEnd = end;
        return this;
      }) ||
        /* browser not supported */
      function() {
        return null;
      }
    )();
  };
})(jQuery);

/* eof */
