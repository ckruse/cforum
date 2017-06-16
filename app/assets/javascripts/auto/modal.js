/* -* coding: utf-8 -*- */

/*
 * A lot of this code is from <https://github.com/gdkraus/accessible-modal-dialog/>
 * gdkruas did a *lot* of great work for accessible modals, thank you very much
 */

/* global jQuery */

(function($) {
  var Modal = function(element, options) {
    this.options = options;
    this.$element = $(element);
    this.$main = $(options.main);
    this.$backdrop = null;
    this.isShown = null;
    this.focusedElementBeforeModal = null;
    this.handlersSet = false;

    this.$backdrop = $("#modal-backdrop");

    if(this.$backdrop.length === 0) {
      $(document.body).append("<div id=\"modal-backdrop\" tabindex=\"-1\" style=\"display:none\"></div>");
      this.$backdrop = $("#modal-backdrop");
    }
  };

  Modal.DEFAULTS = { main: 'main', mainAction: null, cancelAction: null };
  Modal.focusableElementsString = "a[href], area[href], input:not([disabled]), select:not([disabled]), textarea:not([disabled]), button:not([disabled]), iframe, object, embed, *[tabindex], *[contenteditable]";

  Modal.prototype.show = function() {
    var that = this;
    this.$main.attr('aria-hidden', 'true'); // mark the main page as hidden
    this.$backdrop.css('display', 'block'); // insert an overlay to prevent clicking and make a visual change to indicate the main apge is not available
    this.$element.addClass('visible');
    this.$element.attr('aria-hidden', 'false'); // mark the modal window as visible

    // attach a listener to redirect the tab to the modal window if the user somehow gets out of the modal window
    $(document.body).on('focusin', this.options.main, function() {
      that.setFocusToFirstItemInModal();
    });

    // save current focus
    this.focusedElementBeforeModal = $(':focus');
    this.setFocusToFirstItemInModal(this.$element);

    if(!this.handlersSet) {
      this.setEventHandlers();
      this.handlersSet = true;
    }
  };

  Modal.prototype.setEventHandlers = function() {
    var that = this;

    this.$element.find('button[data-modal="dismiss"]').on('click', function(e) {
      if(that.options.cancelAction) {
        that.options.cancelAction.apply(that);
      }

      that.hide();
    });

    this.$element.find('button[data-modal="primary"]').on('click', function(e) {
      if(that.options.primaryAction) {
        that.options.primaryAction.apply(that);
      }
    });

    this.$element.on('keydown', function(event) { that.trapTabKey(event); });
    this.$element.on('keydown', function(event) { that.trapEscapeKey(event); });
  };

  Modal.prototype.trapEscapeKey = function(evt) {
    // if escape pressed
    if (evt.which == 27) {
      // get list of focusable items
      var cancelElement = this.$element.find('button[data-modal="dismiss"]');

      // close the modal window
      cancelElement.click();
      evt.preventDefault();
    }
  };

  Modal.prototype.trapTabKey = function(evt) {
    // if tab or shift-tab pressed
    if (evt.which == 9) {
      // get list of all children elements in given object
      var o = this.$element.find('*');

      // get list of focusable items
      var focusableItems;
      focusableItems = o.filter(Modal.focusableElementsString).filter(':visible');

      // get currently focused item
      var focusedItem;
      focusedItem = $(':focus');

      // get the number of focusable items
      var numberOfFocusableItems;
      numberOfFocusableItems = focusableItems.length;

      // get the index of the currently focused item
      var focusedItemIndex;
      focusedItemIndex = focusableItems.index(focusedItem);

      if(evt.shiftKey) {
        // back tab
        // if focused on first item and user preses back-tab, go to the last focusable item
        if(focusedItemIndex === 0) {
          focusableItems.get(numberOfFocusableItems - 1).focus();
          evt.preventDefault();
        }
      }
      else {
        //forward tab
        // if focused on the last item and user preses tab, go to the first focusable item
        if(focusedItemIndex == numberOfFocusableItems - 1) {
          focusableItems.get(0).focus();
          evt.preventDefault();
        }
      }
    }
  };

  Modal.prototype.hide = function() {
    this.$backdrop.css('display', 'none'); // remove the overlay in order to make the main screen available again
    this.$element.removeClass('visible');
    this.$element.attr('aria-hidden', 'true'); // mark the modal window as hidden
    this.$main.attr('aria-hidden', 'false'); // mark the main page as visible

    // remove the listener which redirects tab keys in the main content area to the modal
    $(document.body).off('focusin', this.options.main);

    // set focus back to element that had it before the modal was opened
    this.focusedElementBeforeModal.focus();
  };

  Modal.prototype.setFocusToFirstItemInModal = function() {
    // get list of all children elements in given object
    var o = this.$element.find('*');

    // set the focus to the first keyboard focusable item
    o.filter(Modal.focusableElementsString).filter(':visible').first().focus();
  };

  function Plugin(option, _relatedTarget) {
    return this.each(function () {
      var $this   = $(this);
      var data    = $this.data('cf.modal');
      var options = $.extend({}, Modal.DEFAULTS, $this.data(), typeof option == 'object' && option);

      if(!data) {
        $this.data('cf.modal', (data = new Modal(this, options)));
      }
      else {
        data.options = options;
      }

      if(typeof option == 'string') {
        data[option](_relatedTarget);
      }
      else if(options.show) {
        data.show(_relatedTarget);
      }
    });
  }

  $.fn.modal = Plugin;
  $.fn.modal.Constructor = Modal;

})(jQuery);

/* eof */
