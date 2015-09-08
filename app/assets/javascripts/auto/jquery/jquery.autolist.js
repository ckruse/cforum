/* -*- coding: utf-8 -*- */

(function($) {
  $.fn.autolist = function(opts) {
    var $this = $(this);
    var nodeHtml = function(node) { return $("<div/>").append(node.clone()).html(); };

    var defaults = {
      rowSelector: "li",
      elementSelector: "input, select, textarea",
      deletionSelector: ".delete",
      callbackDelete: null,
      callbackAfterDelete: null,
      callbackAdd: null,

      checkForUpdate: function() {
        var last_empty = true;
        var last_row = $this.find(defaults.rowSelector + ":last");

        last_row.find(defaults.elementSelector).each(function() {
          if($(this).val()) {
            last_empty = false;
          }
        });


        if(!last_empty) {
          $this.append(last_row.clone());
          last_row = $this.find(defaults.rowSelector + ":last");
          last_row.find(defaults.elementSelector).val("");

          if(defaults.callbackAdd) {
            defaults.callbackAdd.call(last_row);
          }

          last_row.fadeIn('fast');
        }
      },

      checkForRemoval: function() {
        var empty_rows = [];

        $this.find(defaults.rowSelector).each(function() {
          var empty = true;

          $(this).find(defaults.elementSelector).each(function() {
            if($(this).val()) {
              empty = false;
            }
          });

          if(empty) {
            empty_rows.push(this);
          }
        });

        var last_empty = true;
        var last_row = $this.find(defaults.rowSelector + ":last");
        last_row.find(defaults.elementSelector).each(function() {
          if($(this).val()) {
            last_empty = false;
          }
        });

        var last = empty_rows.length;
        if(empty_rows[last - 1] == last_row.get(0)) {
          last -= 1;
        }

        var fn = function() {
          $(this).remove();

          if(defaults.callbackAfterDelete) {
            defaults.callbackAfterDelete.call(this);
          }
        };

        for(var i = 0; i < last; ++i) {
          if(defaults.callbackDelete) {
            defaults.callbackDelete.call(empty_rows[i]);
          }

          $(empty_rows[i]).fadeOut('fast', fn);
        }
      }
    };

    $.extend(defaults, opts);

    $this.on('keyup', defaults.checkForUpdate);
    $this.on('change', defaults.checkForUpdate);

    $this.on('focusout', defaults.checkForRemoval);
    $this.on('change', defaults.checkForRemoval);

    $this.on('click', function(ev) {
      var $trg = $(ev.target);
      var last;

      if($trg.is(defaults.deletionSelector)) {
        var $element = $trg.closest(defaults.rowSelector);

        if(defaults.callbackDelete) {
          defaults.callbackDelete.call($element.get(0));
        }

        $element.fadeOut('fast', function() {
          $(this).remove();

          if(defaults.callbackAfterDelete) {
            defaults.callbackAfterDelete.call(this);
          }

          if($this.find(defaults.rowSelector).length === 0) {
            $this.append($element.clone());

            last = $this.find(defaults.rowSelector + ":last");
            last.find(defaults.elementSelector).val("");

            if(defaults.callbackAdd) {
              defaults.callbackAdd.call(last);
            }

            last.fadeIn("fast");
          }
          else {
            var all_empty = 0;
            $this.find(defaults.rowSelector).each(function() {
              var is_empty = true;
              $(this).find(defaults.elementSelector).each(function() {
                if($(this).val()) {
                  is_empty = false;
                }
              });

              if(is_empty) {
                ++all_empty;
              }
            });

            if(all_empty === 0) {
              $this.append($element.clone());

              last = $this.find(defaults.rowSelector + ":last");
              last.find(defaults.elementSelector).val("");

              if(defaults.callbackAdd) {
                defaults.callbackAdd.call(last);
              }

              last.fadeIn("fast");
            }
          }
        });
      }

    });

  };
})(jQuery);

/* eof */
