/* ===================================================
 * bootstrap-markdown.js v2.8.0
 * http://github.com/toopay/bootstrap-markdown
 * ===================================================
 * Copyright 2013-2014 Taufan Aditya
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ========================================================== */
/* global cforum, t */

(function($) {

  'use strict';

  /* MARKDOWN CLASS DEFINITION
   * ========================== */

  var Markdown = function(element, options) {

    element = $(element);
    options = (options != null) ? options : {};

    var list = [
      'autofocus',
      'disabledButtons',
      'footer',
      'fullscreen',
      'height',
      'hiddenButtons',
      'hideable',
      'iconlibrary',
      'language',
      'resize',
      'savable',
      'width'
    ];

    list.forEach(function(name) {
      if(typeof element.data(name) !== 'undefined') {
        options[name] = element.data(name);
      }
    });

    this.$ns = 'bootstrap-markdown';
    this.$element = element;

    this.$editable = {
      el: null,
      type: null,
      attrKeys: [],
      attrValues: [],
      content: null
    };

    this.$options = $.extend(
      true, {},
      $.fn.markdown.defaults, options, element.data('options')
    );

    this.$oldContent = null;
    this.$isPreview = false;
    this.$isFullscreen = false;
    this.$editor = null;
    this.$textarea = null;
    this.$handler = [];
    this.$callback = [];
    this.$nextTab = [];

    this.showEditor();
  };

  Markdown.prototype = {

    constructor: Markdown,


    __alterButtons: function(name, alter) {
      var handler = this.$handler,
          isAll = (name == 'all'),
          that = this;

      $.each(handler, function(k, v) {
        var halt = true;
        if(isAll) {
          halt = false;
        }
        else {
          halt = v.indexOf(name) < 0;
        }

        if(halt === false) {
          alter(that.$editor.find('button[data-handler="' + v + '"]'));
        }
      });
    },


    __buildButtons: function(buttonsArray, container) {
      var i, ns = this.$ns,
          handler = this.$handler,
          callback = this.$callback;

      for(i = 0; i < buttonsArray.length; i++) {
        // Build each group container
        var y, btnGroups = buttonsArray[i];
        for(y = 0; y < btnGroups.length; y++) {
          // Build each button group
          var z, buttons = btnGroups[y].data,
              btnGroupContainer = $('<div/>', {
                'class': 'btn-group ' + btnGroups[y].name
              });

          for(z = 0; z < buttons.length; z++) {
            var button = buttons[z],
                buttonContainer, buttonIconContainer, buttonHandler = ns + '-' + button.name,
                buttonIcon = this.__getIcon(button.icon),
                btnText = button.btnText ? button.btnText : '',
                btnClass = button.btnClass ? button.btnClass : 'btn',
                tabIndex = button.tabIndex ? button.tabIndex : '-1',
                hotkey = typeof button.hotkey !== 'undefined' ? button.hotkey : '',
                hotkeyCaption = typeof jQuery.hotkeys !== 'undefined' && hotkey !== '' ? ' (' + hotkey + ')' : '';

            // Construct the button object
            buttonContainer = $('<button></button>');
            buttonContainer.text(' ' + this.__localize(btnText)).addClass('btn-default btn-sm').addClass(btnClass);
            if(btnClass.match(/btn\-(primary|success|info|warning|danger|link)/)) {
              buttonContainer.removeClass('btn-default');
            }
            buttonContainer.attr({
              'type': 'button',
              'title': this.__localize(button.title) + hotkeyCaption,
              'tabindex': tabIndex,
              'data-provider': ns,
              'data-handler': buttonHandler,
              'data-hotkey': hotkey
            });
            if(button.toggle === true) {
              buttonContainer.attr('data-toggle', 'button');
            }
            buttonIconContainer = $('<span/>');
            buttonIconContainer.addClass(buttonIcon);
            buttonIconContainer.prependTo(buttonContainer);

            // Attach the button object
            btnGroupContainer.append(buttonContainer);

            // Register handler and callback
            handler.push(buttonHandler);
            callback.push(button.callback);
          }

          // Attach the button group into container dom
          container.append(btnGroupContainer);
        }
      }

      return container;
    },


    __setListener: function() {
      // Set size and resizable Properties
      var hasRows = typeof this.$textarea.attr('rows') !== 'undefined',
          maxRows = this.$textarea.val().split("\n").length > 5 ? this.$textarea.val().split("\n").length : '5',
          rowsVal = hasRows ? this.$textarea.attr('rows') : maxRows;

      this.$textarea.attr('rows', rowsVal);
      if(this.$options.resize) {
        this.$textarea.css('resize', this.$options.resize);
      }

      this.$textarea.on('focus', $.proxy(this.focus, this));
      this.$textarea.on('keypress', $.proxy(this.keypress, this));
      this.$textarea.on('keyup', $.proxy(this.keyup, this));
      this.$textarea.on('change', $.proxy(this.change, this));

      if(this.eventSupported('keydown')) {
        this.$textarea.on('keydown', $.proxy(this.keydown, this));
      }

      // Re-attach markdown data
      this.$textarea.data('markdown', this);
    },


    __handle: function(e) {
      var target = $(e.currentTarget),
          handler = this.$handler,
          callback = this.$callback,
          handlerName = target.attr('data-handler'),
          callbackIndex = handler.indexOf(handlerName),
          callbackHandler = callback[callbackIndex];

      // Trigger the focusin
      $(e.currentTarget).focus();

      callbackHandler(this);

      // Trigger onChange for each button handle
      this.change(this);
      this.$textarea.change();

      // Unless it was the save handler,
      // focusin the textarea
      if(handlerName.indexOf('cmdSave') < 0) {
        this.$textarea.focus();
      }

      e.preventDefault();
    },


    __localize: function(string) {
      var messages = $.fn.markdown.messages,
          language = this.$options.language;
      if(
          typeof messages !== 'undefined' &&
          typeof messages[language] !== 'undefined' &&
          typeof messages[language][string] !== 'undefined'
      ) {
        return messages[language][string];
      }
      return string;
    },


    __getIcon: function(src) {
      return typeof src == 'object' ? src[this.$options.iconlibrary] : src;
    },


    __isBeginningOfLine: function(content, selection) {
      var start = selection.start;
      return (start === 0) || (content.substr(start - 1, 1) === '\n');
    },


    __previousLineIsList: function(content, sel, rx) {
      var i, c;

      for(i = sel.start - 1; i >= 0; --i) {

        c = content.substr(i, 1);
        if(c == "\n") {
          if(content.substr(i + 1, 1).match(rx)) {
            return true;
          }
        }
      }

      return (i === 0);
    },


    setFullscreen: function(mode) {
      var $editor = this.$editor,
          $textarea = this.$textarea;

      if(mode === true) {
        $editor.addClass('md-fullscreen-mode');
        $('body').addClass('md-nooverflow');
        this.$options.onFullscreen(this);
      }
      else {
        $editor.removeClass('md-fullscreen-mode');
        $('body').removeClass('md-nooverflow');
      }

      this.$isFullscreen = mode;
      $textarea.focus();
    },


    showEditor: function() {
      var instance = this,
          textarea, ns = this.$ns,
          container = this.$element,
          originalHeigth = container.css('height'),
          originalWidth = container.css('width'),
          editable = this.$editable,
          handler = this.$handler,
          callback = this.$callback,
          options = this.$options,
          editor = $('<div/>', {
            'class': 'md-editor',
            click: function() {
              instance.focus();
            }
          });

      // Prepare the editor
      if(this.$editor === null) {
        // Create the panel
        var editorHeader = $('<div/>', {
          'class': 'md-header btn-toolbar'
        });

        // Merge the main & additional button groups together
        var allBtnGroups = [];
        if(options.buttons.length > 0) allBtnGroups = allBtnGroups.concat(options.buttons[0]);
        if(options.additionalButtons.length > 0) allBtnGroups = allBtnGroups.concat(options.additionalButtons[0]);

        // Reduce and/or reorder the button groups
        if(options.reorderButtonGroups.length > 0) {
          allBtnGroups = allBtnGroups
            .filter(function(btnGroup) {
              return options.reorderButtonGroups.indexOf(btnGroup.name) > -1;
            })
            .sort(function(a, b) {
              if(options.reorderButtonGroups.indexOf(a.name) < options.reorderButtonGroups.indexOf(b.name)) return -1;
              if(options.reorderButtonGroups.indexOf(a.name) > options.reorderButtonGroups.indexOf(b.name)) return 1;
              return 0;
            });
        }

        if(options.fullscreen.enable) {
          editorHeader.append('<div class="md-controls"><a class="md-control md-control-fullscreen" href="#"><span class="' + this.__getIcon(options.fullscreen.icons.fullscreenOn) + '"></span></a></div>').on('click', '.md-control-fullscreen', function(e) {
            e.preventDefault();
            instance.setFullscreen(true);
          });
        }

        // Build the buttons
        if(allBtnGroups.length > 0) {
          editorHeader = this.__buildButtons([allBtnGroups], editorHeader);
        }

        editor.append(editorHeader);

        // Wrap the textarea
        if(container.is('textarea')) {
          container.before(editor);
          textarea = container;
          textarea.addClass('md-input');
          editor.append(textarea);
        }
        else {
          var rawContent = (typeof toMarkdown == 'function') ? toMarkdown(container.html()) : container.html(),
              currentContent = $.trim(rawContent);

          // This is some arbitrary content that could be edited
          textarea = $('<textarea/>', {
            'class': 'md-input',
            'val': currentContent
          });

          editor.append(textarea);

          // Save the editable
          editable.el = container;
          editable.type = container.prop('tagName').toLowerCase();
          editable.content = container.html();

          $(container[0].attributes).each(function() {
            editable.attrKeys.push(this.nodeName);
            editable.attrValues.push(this.nodeValue);
          });

          // Set editor to blocked the original container
          container.replaceWith(editor);
        }

        var editorFooter = $('<div/>', {
          'class': 'md-footer'
        }),
            createFooter = false,
            footer = '';
        // Create the footer if savable
        if(options.savable) {
          createFooter = true;
          var saveHandler = 'cmdSave';

          // Register handler and callback
          handler.push(saveHandler);
          callback.push(options.onSave);

          editorFooter.append('<button class="btn btn-success" data-provider="' + ns + '" data-handler="' + saveHandler + '"><i class="icon icon-white icon-ok"></i> ' + this.__localize('Save') + '</button>');


        }

        footer = typeof options.footer === 'function' ? options.footer(this) : options.footer;

        if($.trim(footer) !== '') {
          createFooter = true;
          editorFooter.append(footer);
        }

        if(createFooter) editor.append(editorFooter);

        // Set width
        if(options.width && options.width !== 'inherit') {
          if(jQuery.isNumeric(options.width)) {
            editor.css('display', 'table');
            textarea.css('width', options.width + 'px');
          }
          else {
            editor.addClass(options.width);
          }
        }

        // Set height
        if(options.height && options.height !== 'inherit') {
          if(jQuery.isNumeric(options.height)) {
            var height = options.height;
            if(editorHeader) height = Math.max(0, height - editorHeader.outerHeight());
            if(editorFooter) height = Math.max(0, height - editorFooter.outerHeight());
            textarea.css('height', height + 'px');
          }
          else {
            editor.addClass(options.height);
          }
        }

        // Reference
        this.$editor = editor;
        this.$textarea = textarea;
        this.$editable = editable;
        this.$oldContent = this.getContent();

        this.__setListener();

        // Set editor attributes, data short-hand API and listener
        this.$editor.attr('id', (new Date()).getTime());
        this.$editor.on('click', '[data-provider="bootstrap-markdown"]', $.proxy(this.__handle, this));

        if(this.$element.is(':disabled') || this.$element.is('[readonly]')) {
          this.$editor.addClass('md-editor-disabled');
          this.disableButtons('all');
        }

        if(this.eventSupported('keydown') && typeof jQuery.hotkeys === 'object') {
          editorHeader.find('[data-provider="bootstrap-markdown"]').each(function() {
            var $button = $(this),
                hotkey = $button.attr('data-hotkey');
            if(hotkey.toLowerCase() !== '') {
              textarea.bind('keydown', hotkey, function() {
                $button.trigger('click');
                return false;
              });
            }
          });
        }

        if(options.initialstate === 'preview') {
          this.showPreview();
        }
        else if(options.initialstate === 'fullscreen' && options.fullscreen.enable) {
          this.setFullscreen(true);
        }

      }
      else {
        this.$editor.show();
      }

      if(options.autofocus) {
        this.$textarea.focus();
        this.$editor.addClass('active');
      }

      if(options.fullscreen.enable && options.fullscreen !== false) {
        this.$editor.append('\
          <div class="md-fullscreen-controls">\
            <a href="#" class="exit-fullscreen" title="Exit fullscreen"><span class="' + this.__getIcon(options.fullscreen.icons.fullscreenOff) + '"></span></a>\
          </div>');

        this.$editor.on('click', '.exit-fullscreen', function(e) {
          e.preventDefault();
          instance.setFullscreen(false);
        });
      }

      // hide hidden buttons from options
      this.hideButtons(options.hiddenButtons);

      // disable disabled buttons from options
      this.disableButtons(options.disabledButtons);

      // Trigger the onShow hook
      options.onShow(this);

      return this;
    },


    parseContent: function(val) {
      var content;

      // parse with supported markdown parser
      var val = val || this.$textarea.val();

      if(typeof markdown == 'object') {
        content = markdown.toHTML(val);
      }
      else if(typeof marked == 'function') {
        content = marked(val);
      }
      else {
        content = val;
      }

      return content;
    },


    showPreview: function() {
      var options = this.$options,
          container = this.$textarea,
          afterContainer = container.next(),
          replacementContainer = $('<div/>', {
            'class': 'md-preview',
            'data-provider': 'markdown-preview'
          }),
          content, callbackContent;

      // Give flag that tell the editor enter preview mode
      this.$isPreview = true;
      // Disable all buttons
      this.disableButtons('all').enableButtons('cmdPreview');

      // Try to get the content from callback
      callbackContent = options.onPreview(this);
      // Set the content based from the callback content if string otherwise parse value from textarea
      content = typeof callbackContent == 'string' ? callbackContent : this.parseContent();

      // Build preview element
      replacementContainer.html(content);

      if(afterContainer && afterContainer.attr('class') == 'md-footer') {
        // If there is footer element, insert the preview container before it
        replacementContainer.insertBefore(afterContainer);
      }
      else {
        // Otherwise, just append it after textarea
        container.parent().append(replacementContainer);
      }

      // Set the preview element dimensions
      replacementContainer.css({
        width: container.outerWidth() + 'px',
        height: container.outerHeight() + 'px'
      });

      if(this.$options.resize) {
        replacementContainer.css('resize', this.$options.resize);
      }

      // Hide the last-active textarea
      container.hide();

      // Attach the editor instances
      replacementContainer.data('markdown', this);

      if(this.$element.is(':disabled') || this.$element.is('[readonly]')) {
        this.$editor.addClass('md-editor-disabled');
        this.disableButtons('all');
      }

      return this;
    },


    hidePreview: function() {
      // Give flag that tell the editor quit preview mode
      this.$isPreview = false;

      // Obtain the preview container
      var container = this.$editor.find('div[data-provider="markdown-preview"]');

      // Remove the preview container
      container.remove();

      // Enable all buttons
      this.enableButtons('all');
      // Disable configured disabled buttons
      this.disableButtons(this.$options.disabledButtons);

      // Back to the editor
      this.$textarea.show();
      this.__setListener();

      return this;
    },

    getModal: function(which) {
      var modal = $("#" + which);
      modal.find("input").val("");
      return modal;
    },


    isDirty: function() {
      return this.$oldContent != this.getContent();
    },


    getContent: function() {
      return this.$textarea.val();
    },


    setContent: function(content) {
      this.$textarea.val(content);

      return this;
    },


    findSelection: function(chunk) {
      var content = this.getContent(),
          startChunkPosition;

      if(startChunkPosition = content.indexOf(chunk), startChunkPosition >= 0 && chunk.length > 0) {
        var oldSelection = this.getSelection(),
            selection;

        this.setSelection(startChunkPosition, startChunkPosition + chunk.length);
        selection = this.getSelection();

        this.setSelection(oldSelection.start, oldSelection.end);

        return selection;
      }
      else {
        return null;
      }
    },


    getSelection: function() {

      var e = this.$textarea[0];

      return(

        ('selectionStart' in e && function() {
          var l = e.selectionEnd - e.selectionStart;
          return {
            start: e.selectionStart,
            end: e.selectionEnd,
            length: l,
            text: e.value.substr(e.selectionStart, l)
          };
        }) ||

          /* browser not supported */
        function() {
          return null;
        }

      )();

    },


    setSelection: function(start, end) {

      var e = this.$textarea[0];

      return(

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

    },


    replaceSelection: function(text) {

      var e = this.$textarea[0];

      return(

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
    },


    __getLeadingNewlines: function(content, selected) {
      var newlines = '',
          str = content.substr(selected.start - 2, 2);

      if(str.charAt(1) !== '\n') {
        newlines = '\n\n';
      }
      else if(str.charAt(0) !== '\n') {
        newlines = '\n';
      }

      return newlines;
    },


    getNextTab: function() {
      // Shift the nextTab
      if(this.$nextTab.length === 0) {
        return null;
      }
      else {
        var nextTab, tab = this.$nextTab.shift();

        if(typeof tab == 'function') {
          nextTab = tab();
        }
        else if(typeof tab == 'object' && tab.length > 0) {
          nextTab = tab;
        }

        return nextTab;
      }
    },


    setNextTab: function(start, end) {
      // Push new selection into nextTab collections
      if(typeof start == 'string') {
        var that = this;
        this.$nextTab.push(function() {
          return that.findSelection(start);
        });
      }
      else if(typeof start == 'number' && typeof end == 'number') {
        var oldSelection = this.getSelection();

        this.setSelection(start, end);
        this.$nextTab.push(this.getSelection());

        this.setSelection(oldSelection.start, oldSelection.end);
      }

      return;
    },


    __parseButtonNameParam: function(nameParam) {
      var buttons = [];

      if(typeof nameParam == 'string') {
        buttons = nameParam.split(',');
      }
      else {
        buttons = nameParam;
      }

      return buttons;
    },


    enableButtons: function(name) {
      var buttons = this.__parseButtonNameParam(name),
          that = this;

      $.each(buttons, function(i, v) {
        that.__alterButtons(buttons[i], function(el) {
          el.removeAttr('disabled');
        });
      });

      return this;
    },


    disableButtons: function(name) {
      var buttons = this.__parseButtonNameParam(name),
          that = this;

      $.each(buttons, function(i, v) {
        that.__alterButtons(buttons[i], function(el) {
          el.attr('disabled', 'disabled');
        });
      });

      return this;
    },


    hideButtons: function(name) {
      var buttons = this.__parseButtonNameParam(name),
          that = this;

      $.each(buttons, function(i, v) {
        that.__alterButtons(buttons[i], function(el) {
          el.addClass('hidden');
        });
      });

      return this;
    },


    showButtons: function(name) {
      var buttons = this.__parseButtonNameParam(name),
          that = this;

      $.each(buttons, function(i, v) {
        that.__alterButtons(buttons[i], function(el) {
          el.removeClass('hidden');
        });
      });

      return this;
    },


    eventSupported: function(eventName) {
      var isSupported = eventName in this.$element;
      if(!isSupported) {
        this.$element.setAttribute(eventName, 'return;');
        isSupported = typeof this.$element[eventName] === 'function';
      }
      return isSupported;
    },


    keyup: function(e) {
      var blocked = false;
      switch(e.keyCode) {
      case 40: // down arrow
      case 38: // up arrow
      case 16: // shift
      case 17: // ctrl
      case 18: // alt
      case 9: // tab
        break;

      case 13: // enter
        blocked = false;
        break;
      case 27: // escape
        if(this.$isFullscreen) this.setFullscreen(false);
        blocked = false;
        break;

      default:
        blocked = false;
      }

      if(blocked) {
        e.stopPropagation();
        e.preventDefault();
      }

      this.$options.onChange(this);
    },


    change: function(e) {
      this.$options.onChange(this);
      return this;
    },


    focus: function(e) {
      var options = this.$options,
          isHideable = options.hideable,
          editor = this.$editor;

      editor.addClass('active');

      // Blur other markdown(s)
      $(document).find('.md-editor').each(function() {
        if($(this).attr('id') !== editor.attr('id')) {
          var attachedMarkdown;

          if(attachedMarkdown = $(this).find('textarea').data('markdown'), attachedMarkdown === null) {
            attachedMarkdown = $(this).find('div[data-provider="markdown-preview"]').data('markdown');
          }

          if(attachedMarkdown) {
            attachedMarkdown.blur();
          }
        }
      });

      // Trigger the onFocus hook
      options.onFocus(this);

      return this;
    },


    blur: function(e) {
      var options = this.$options,
          isHideable = options.hideable,
          editor = this.$editor,
          editable = this.$editable;

      if(editor.hasClass('active') || this.$element.parent().length === 0) {
        editor.removeClass('active');

        if(isHideable) {
          // Check for editable elements
          if(editable.el !== null) {
            // Build the original element
            var oldElement = $('<' + editable.type + '/>'),
                content = this.getContent(),
                currentContent = (typeof markdown == 'object') ? markdown.toHTML(content) : content;

            $(editable.attrKeys).each(function(k, v) {
              oldElement.attr(editable.attrKeys[k], editable.attrValues[k]);
            });

            // Get the editor content
            oldElement.html(currentContent);

            editor.replaceWith(oldElement);
          }
          else {
            editor.hide();
          }
        }

        // Trigger the onBlur hook
        options.onBlur(this);
      }

      return this;
    }

  };

  /* MARKDOWN PLUGIN DEFINITION
   * ========================== */

  var old = $.fn.markdown;

  $.fn.markdown = function(option) {
    return this.each(function() {
      var $this = $(this),
          data = $this.data('markdown'),
          options = typeof option == 'object' && option;
      if(!data) {
        $this.data('markdown', (data = new Markdown(this, options)));
      }
    });
  };

  $.fn.markdown.messages = {};

  $.fn.markdown.defaults = {
    /* Editor Properties */
    autofocus: false,
    hideable: false,
    savable: false,
    width: 'inherit',
    height: 'inherit',
    resize: 'none',
    iconlibrary: 'glyph',
    language: 'en',
    initialstate: 'editor',

    /* Buttons Properties */
    buttons: [
      [{
        name: 'groupFont',
        data: [{
          name: 'cmdBold',
          hotkey: 'Ctrl+B',
          title: 'Bold',
          tabIndex: '0',
          icon: {
            glyph: 'glyphicon glyphicon-bold',
            fa: 'fa fa-bold',
            'fa-3': 'icon-bold'
          },
          callback: function(e) {
            // Give/remove ** surround the selection
            var chunk, cursor, selected = e.getSelection(),
                content = e.getContent();

            if(selected.length === 0) {
              // Give extra word
              chunk = e.__localize('strong text');
            }
            else {
              chunk = selected.text;
            }

            // transform selection and set the cursor into chunked text
            if(content.substr(selected.start - 2, 2) === '**' && content.substr(selected.end, 2) === '**') {
              e.setSelection(selected.start - 2, selected.end + 2);
              e.replaceSelection(chunk);
              cursor = selected.start - 2;
            }
            else {
              e.replaceSelection('**' + chunk + '**');
              cursor = selected.start + 2;
            }

            // Set the cursor
            e.setSelection(cursor, cursor + chunk.length);
          }
        }, {
          name: 'cmdItalic',
          title: 'Italic',
          hotkey: 'Ctrl+I',
          tabIndex: '0',
          icon: {
            glyph: 'glyphicon glyphicon-italic',
            fa: 'fa fa-italic',
            'fa-3': 'icon-italic'
          },
          callback: function(e) {
            // Give/remove * surround the selection
            var chunk, cursor, selected = e.getSelection(),
                content = e.getContent();

            if(selected.length === 0) {
              // Give extra word
              chunk = e.__localize('emphasized text');
            }
            else {
              chunk = selected.text;
            }

            // transform selection and set the cursor into chunked text
            if(content.substr(selected.start - 1, 1) === '*' && content.substr(selected.end, 1) === '*') {
              e.setSelection(selected.start - 1, selected.end + 1);
              e.replaceSelection(chunk);
              cursor = selected.start - 1;
            }
            else {
              e.replaceSelection('*' + chunk + '*');
              cursor = selected.start + 1;
            }

            // Set the cursor
            e.setSelection(cursor, cursor + chunk.length);
          }
        }, {
          name: 'cmdHeading',
          title: 'Heading',
          hotkey: 'Ctrl+H',
          tabIndex: '0',
          icon: {
            glyph: 'glyphicon glyphicon-header',
            fa: 'fa fa-header',
            'fa-3': 'icon-font'
          },
          callback: function(e) {
            // Append/remove ### surround the selection
            var chunk, cursor, selected = e.getSelection(),
                content = e.getContent(),
                pointer, prevChar;

            if(selected.length === 0) {
              // Give extra word
              chunk = e.__localize('heading text');
            }
            else {
              chunk = selected.text + '\n';
            }

            // transform selection and set the cursor into chunked text
            if((pointer = 4, content.substr(selected.start - pointer, pointer) === '### ') || (pointer = 3, content.substr(selected.start - pointer, pointer) === '###')) {
              e.setSelection(selected.start - pointer, selected.end);
              e.replaceSelection(chunk);
              cursor = selected.start - pointer;
            }
            else if(selected.start > 0 && (prevChar = content.substr(selected.start - 1, 1), !!prevChar && prevChar != '\n')) {
              e.replaceSelection('\n\n### ' + chunk);
              cursor = selected.start + 6;
            }
            else {
              // Empty string before element
              e.replaceSelection('### ' + chunk);
              cursor = selected.start + 4;
            }

            // Set the cursor
            e.setSelection(cursor, cursor + chunk.length);
          }
        }]
      }, {
        name: 'groupLink',
        data: [{
          name: 'cmdUrl',
          title: 'URL/Link',
          hotkey: 'Ctrl+L',
          tabIndex: '0',
          icon: {
            glyph: 'glyphicon glyphicon-link',
            fa: 'fa fa-link',
            'fa-3': 'icon-link'
          },
          callback: function(e) {
            // Give [] surround the selection and prepend the link
            var chunk, selected = e.getSelection(),
                content = e.getContent(),
                link;

            if(selected.length !== 0) {
              chunk = selected.text;
            }

            var modal = e.getModal('md-link-modal');
            $("#md-hyperlink-title").val(chunk);
            modal.modal({
              show: true,
              main: '#page-container',
              primaryAction: function() {
                link = $("#md-hyperlink-href").val();
                chunk = $("#md-hyperlink-title").val();

                if(link !== null && link !== '' && link !== 'http://' && link.substr(0, 4) === 'http') {
                  modal.modal('hide');
                  var sanitizedLink = $('<div>' + link + '</div>').text();

                  // transform selection and set the cursor into chunked text
                  var text = "";
                  if(chunk) {
                    text = '[' + chunk + '](' + sanitizedLink + ')';
                  }
                  else {
                    text = '<' + sanitizedLink + '>';
                  }

                  e.replaceSelection(text);
                  e.setSelection(selected.start, selected.start + text.length);
                  e.$textarea.trigger('input');
                  e.$textarea.focus();
                }
                else {
                  $("#md-hyperlink-href").closest('.cf-cgroup').addClass('error');
                  $("#md-hyperlink-href").focus();
                }
              }
            });
          }
        }, {
          name: 'cmdImage',
          title: 'Image',
          hotkey: 'Ctrl+G',
          tabIndex: '0',
          icon: {
            glyph: 'glyphicon glyphicon-picture',
            fa: 'fa fa-picture-o',
            'fa-3': 'icon-picture'
          },
          callback: function(e) {
            // Give ![] surround the selection and prepend the image link
            var chunk, cursor, selected = e.getSelection(),
                content = e.getContent(),
                link, title;

            if(selected.length !== 0) {
              chunk = selected.text;
            }

            var modal = e.getModal('md-img-modal');
            modal.find("#md-img-desc").val(chunk);
            modal.modal({
              show: true,
              main: '#page-container',
              primaryAction: function() {
                $("#md-img-modal [data-modal=primary]")
                  .addClass('loading')
                  .prop('disabled', true);

                cforum.uploadFile(document.getElementById("md-img-src"), function(response) {
                  $("#md-img-modal [data-modal=primary]")
                    .removeClass('loading')
                    .prop('disabled', false);

                  modal.modal('hide');

                  link = cforum.basePath + 'images/' + response.path;
                  chunk = $("#md-img-desc").val();
                  title = $("#md-img-title").val();

                  var sanitizedLink = $('<div>' + link + '</div>').text();

                  var md = '[![' + chunk + '](' + cforum.basePath + 'images/' + response.path + '?size=medium';
                  if(title) {
                    md += ' "' + title + '"';
                  }
                  md += ')](' + cforum.basePath + 'images/' + response.path + ')';

                  e.replaceSelection(md);
                  cursor = selected.start;
                  e.setSelection(cursor, cursor + md.length);

                  e.$textarea.trigger('input');
                  e.$textarea.focus();
                },
                function(response) {
                  modal.modal('hide');
                  $("#md-img-modal [data-modal=primary]")
                    .removeClass('loading')
                    .prop('disabled', false);

                  var msg;

                  if(typeof response == 'string') {
                    msg = response;
                  }
                  else if(response.error) {
                    msg = response.error;
                  }
                  else {
                    msg = t('internal_error');
                  }

                  cforum.alert.error(msg);
                });
              }
            });
          }
        }]
      }, {
        name: 'groupMisc',
        data: [{
          name: 'cmdList',
          hotkey: 'Ctrl+U',
          title: 'Unordered List',
          tabIndex: '0',
          icon: {
            glyph: 'glyphicon glyphicon-list',
            fa: 'fa fa-list',
            'fa-3': 'icon-list-ul'
          },
          callback: function(e) {
            // Prepend/Give - surround the selection
            var chunk, cursor, selected = e.getSelection(),
                content = e.getContent(), prefix = "";

            // transform selection and set the cursor into chunked text
            if(selected.length === 0) {
              // Give extra word
              chunk = e.__localize('list text here');

              if(!e.__previousLineIsList(content, selected, /-/)) {
                prefix += "\n";
              }
              if(!e.__isBeginningOfLine(content, selected)) {
                prefix += "\n";
              }

              e.replaceSelection(prefix + '- ' + chunk);
              // Set the cursor
              cursor = selected.start + 2 + prefix.length;
            }
            else {
              if(selected.text.indexOf('\n') < 0) {
                chunk = selected.text;

                e.replaceSelection('- ' + chunk);

                // Set the cursor
                cursor = selected.start + 2;
              }
              else {
                var list = [];

                list = selected.text.split('\n');
                chunk = list[0];

                list = list.map(function(string) {
                  return '- ' + string;
                });

                var start = e.__getLeadingNewlines(content, selected);
                e.replaceSelection(start + list.join('\n'));

                // Set the cursor
                cursor = selected.start + 2 + start.length;
              }
            }

            // Set the cursor
            e.setSelection(cursor, cursor + chunk.length);
          }
        }, {
          name: 'cmdListO',
          hotkey: 'Ctrl+O',
          title: 'Ordered List',
          tabIndex: '0',
          icon: {
            glyph: 'glyphicon glyphicon-th-list',
            fa: 'fa fa-list-ol',
            'fa-3': 'icon-list-ol'
          },
          callback: function(e) {

            // Prepend/Give - surround the selection
            var chunk, cursor, selected = e.getSelection(),
                content = e.getContent(), prefix = "";

            // transform selection and set the cursor into chunked text
            if(selected.length === 0) {
              // Give extra word
              chunk = e.__localize('list text here');

              if(!e.__previousLineIsList(content, selected, /\d/)) {
                prefix += "\n";
              }
              if(!e.__isBeginningOfLine(content, selected)) {
                prefix += "\n";
              }

              e.replaceSelection(prefix + '1. ' + chunk);
              // Set the cursor
              cursor = selected.start + 3 + prefix.length;
            }
            else {
              if(selected.text.indexOf('\n') < 0) {
                chunk = selected.text;

                e.replaceSelection('1. ' + chunk);

                // Set the cursor
                cursor = selected.start + 3;
              }
              else {
                var list = [];

                list = selected.text.split('\n');
                chunk = list[0];

                list = list.map(function(string, index) {
                  return (index + 1) + '. ' + string;
                });

                var start = e.__getLeadingNewlines(content, selected);
                e.replaceSelection(start + list.join('\n'));

                // Set the cursor
                cursor = selected.start + 3 + start.length;
              }
            }

            // Set the cursor
            e.setSelection(cursor, cursor + chunk.length);
          }
        }, {
          name: 'cmdCode',
          hotkey: 'Ctrl+K',
          title: 'Code',
          tabIndex: '0',
          icon: {
            glyph: 'glyphicon glyphicon-asterisk',
            fa: 'fa fa-code',
            'fa-3': 'icon-code'
          },
          callback: function(e) {
            // Get content and selection
            var content = e.getContent(), selection = e.getSelection();

            // Get selected text
            var text = (selection.length === 0) ? e.__localize('code text here') : selection.text;

            // Define conditions
            var selectionIsCodeBlock = function() {
              return (
                (content.substr(selection.start - 4, 4) === '~~~\n') &&
                (content.substr(selection.end, 4) === '\n~~~')
              );
            };

            var selectionIsInlineCode = function() {
              return (
                (content.charAt(selection.start - 1) === '`') &&
                (content.charAt(selection.end) === '`')
              );
            };

            var selectionContainsNewlines = function() {
              return (text.indexOf('\n') > -1);
            };

            var selectionIsPrecededByNewlines = function() {
              return (content.substr(selection.start - 2, 2) === '\n\n');
            };

            var selectionIsWholeLine = function() {
              return (selection.end === content.length) || (content.charAt(selection.end) === '\n');
            };

            var languageIsValid = function(lang) {
              return (lang != null) && (lang.length < 20);
            };

            // Define actions
            var removeMarkup = function(type) {
              var characters = { block: 4, inline: 1 }[type];
              var cursor = selection.start - characters;
              e.setSelection(cursor, selection.end + characters);
              e.replaceSelection(text);
              e.setSelection(cursor, cursor + text.length);
            };

            var createInlineCode = function() {
              var cursor = selection.start + 1;
              e.replaceSelection('`' + text + '`');
              e.setSelection(cursor, cursor + text.length);
            };

            var createCodeBlock = function() {
              var msgModal = e.getModal('md-code-modal');
              msgModal.modal({
                show: true,
                main: '#page-container',
                primaryAction: function() {
                  msgModal.modal('hide');

                  var lang = $("#md-code-lang").val();
                  if(languageIsValid(lang)) {
                    var prefix = e.__getLeadingNewlines(content, selection);
                    e.replaceSelection(prefix + '~~~' + lang + '\n' + text + '\n~~~\n');
                    var cursor = selection.start + 4 + prefix.length + lang.length;
                    e.setSelection(cursor, cursor + text.length);

                    e.$textarea.trigger('input');
                    e.$textarea.focus();
                  }
                }
              });
            };

            // Do something
            switch(true) {
              case selectionIsCodeBlock():
                removeMarkup('block');
                break;
              case selectionIsInlineCode():
                removeMarkup('inline');
                break;
              case selectionContainsNewlines():
                createCodeBlock();
                break;
              case selectionIsPrecededByNewlines() && selectionIsWholeLine():
                createCodeBlock();
                break;
              default:
                createInlineCode();
            }
          }
        }, {
          name: 'cmdQuote',
          hotkey: 'Ctrl+Q',
          title: 'Quote',
          tabIndex: '0',
          icon: {
            glyph: 'glyphicon glyphicon-comment',
            fa: 'fa fa-quote-left',
            'fa-3': 'icon-quote-left'
          },
          callback: function(e) {
            // Prepend/Give - surround the selection
            var chunk, cursor, selected = e.getSelection(),
                content = e.getContent();

            // transform selection and set the cursor into chunked text
            if(selected.length === 0) {
              // Give extra word
              chunk = e.__localize('quote here');

              e.replaceSelection('> ' + chunk);

              // Set the cursor
              cursor = selected.start + 2;
            }
            else {
              if(selected.text.indexOf('\n') < 0) {
                chunk = selected.text;

                e.replaceSelection('> ' + chunk);

                // Set the cursor
                cursor = selected.start + 2;
              }
              else {
                var list = [];

                list = selected.text.split('\n');
                chunk = list[0];

                $.each(list, function(k, v) {
                  list[k] = '> ' + v;
                });

                e.replaceSelection('\n\n' + list.join('\n'));

                // Set the cursor
                cursor = selected.start + 4;
              }
            }

            // Set the cursor
            e.setSelection(cursor, cursor + chunk.length);
          }
        }]
      }, {
        name: 'groupUtil',
        data: [{
          name: 'cmdPreview',
          toggle: true,
          hotkey: 'Ctrl+P',
          title: 'Preview',
          btnClass: 'btn btn-primary btn-sm',
          tabIndex: '0',
          icon: {
            glyph: 'glyphicon glyphicon-search',
            fa: 'fa fa-search',
            'fa-3': 'icon-search'
          },
          callback: function(e) {
            // Check the preview mode and toggle based on this flag
            var isPreview = e.$isPreview,
                content;

            if(isPreview === false) {
              // Give flag that tell the editor enter preview mode
              e.showPreview();
            }
            else {
              e.hidePreview();
            }
          }
        }]
      }]
    ],
    additionalButtons: [], // Place to hook more buttons by code
    reorderButtonGroups: [],
    hiddenButtons: [], // Default hidden buttons
    disabledButtons: [], // Default disabled buttons
    footer: '',
    fullscreen: {
      enable: true,
      icons: {
        fullscreenOn: {
          fa: 'fa fa-expand',
          glyph: 'glyphicon glyphicon-fullscreen',
          'fa-3': 'icon-resize-full'
        },
        fullscreenOff: {
          fa: 'fa fa-compress',
          glyph: 'glyphicon glyphicon-fullscreen',
          'fa-3': 'icon-resize-small'
        }
      }
    },

    /* Events hook */
    onShow: function(e) {},
    onPreview: function(e) {},
    onSave: function(e) {},
    onBlur: function(e) {},
    onFocus: function(e) {},
    onChange: function(e) {},
    onFullscreen: function(e) {}
  };

  $.fn.markdown.Constructor = Markdown;


  /* MARKDOWN NO CONFLICT
   * ==================== */

  $.fn.markdown.noConflict = function() {
    $.fn.markdown = old;
    return this;
  };


  /* MARKDOWN GLOBAL FUNCTION & DATA-API
   * ==================================== */

  var initMarkdown = function($element) {
    var markdown = $element.data('markdown');
    markdown ? markdown.showEditor() : $element.markdown();
  };

  var blurNonFocused = function(e) {
    var $activeElement = $(document.activeElement);

    // Blur event
    $(document).find('.md-editor').each(function() {
      var $this = $(this),
          focused = $activeElement.closest('.md-editor')[0] === this,
          attachedMarkdown = $this.find('textarea').data('markdown') ||
            $this.find('div[data-provider="markdown-preview"]').data('markdown');

      if(attachedMarkdown && !focused) {
        attachedMarkdown.blur();
      }
    });
  };

  $(document)
    .on('click.markdown.data-api', '[data-provide="markdown-editable"]', function(e) {
      initMarkdown($(this));
      e.preventDefault();
    })
    .on('click focusin', function(e) {
      blurNonFocused(e);
    })
    .ready(function() {
      $('textarea[data-provide="markdown"]').each(function() {
        initMarkdown($(this));
      });
    });

}(window.jQuery));

/* eof */
