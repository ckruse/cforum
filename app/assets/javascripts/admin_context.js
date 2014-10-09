/* -*- coding: utf-8 -*- */
/* global cforum */

$(function() {
  var thread_map = {};
  var message_map = {};

  $(".thread").each(function() {
    var $this = $(this);
    var tid = $this.attr("id");
    var icons = $this.find(".icon-thread");

    if(icons.length > 0) {
      if(!thread_map[tid]) {
        thread_map[tid] = {};
      }

      for(var i = 0; i < icons.length; i++) {
        var t = $(icons[i]);
        var c = t.attr('class').replace(/(icon-thread)|\s+/g, '');;
        thread_map[tid][c] = t;
        t.css('display', 'none');
      }
    }
  });


  $(".message").each(function() {
    var $this = $(this);
    var mid = $this.attr("id");
    var icons = $this.find(".icon-message");

    if(icons.length > 0) {
      if(!message_map[mid]) {
        message_map[mid] = {};
      }

      for(var i = 0; i < icons.length; i++) {
        var t = $(icons[i]);
        var c = t.attr('class').replace(/(icon-message)|\s+/g, '');;
        message_map[mid][c] = t;
        t.css('display', 'none');
      }
    }
  });


  $.contextMenu({
    selector: ".thread h2",
    build: function(trigger, e) {
      var items = {};
      var tid = trigger.closest(".thread").attr("id");
      var mid = trigger.closest(".message").attr("id");

      if(tid && thread_map[tid]) {
        var icons = thread_map[tid];

        for(var key in icons) {
          var t = $(icons[key]);
          items[key] = {name: t.attr('title')};
        }

        var icons = message_map[mid];
        for(var key in icons) {
          var t = $(icons[key]);
          items['m-' + key] = {name: t.attr('title')}
        }
      }

      return {
        items: items,
        callback: function(key, options) {
          if(thread_map[tid] && thread_map[tid][key]) {
            var icon = thread_map[tid][key];
            icon.click();
          }

          key = key.substr(2);
          if(message_map[mid] && message_map[mid][key]) {
            var icon = message_map[mid][key];
            icon.click();
          }
        }
      }
    },
  });

  $.contextMenu({
    selector: ".message h3",
    build: function(trigger, e) {
      var items = {};
      var mid = trigger.closest(".message").attr("id");

      if(mid && message_map[mid]) {
        var icons = message_map[mid];

        for(var key in icons) {
          var t = $(icons[key]);
          items[key] = {name: t.attr('title')};
        }
      }

      return {
        items: items,
        callback: function(key, options) {
          if(message_map[mid]) {
            var icon = message_map[mid][key];
            icon.click();
          }
        }
      }
    },
  })
});

/* eof */
