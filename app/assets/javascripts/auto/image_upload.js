/* -*- coding: utf-8 -*- */

/* global cforum, t */

function ImageUpload(input) {
  input.after('<div class="image-upload">' + t('upload.image_area') + '</div>');
  var zone = input.next('.image-upload');

  var tm = null;
  var elements = $();

  var enter = function(e) {
    window.clearTimeout(tm);
    tm = null;
    zone.addClass('dragging');
    elements = elements.add(e.target);
  };

  var leave = function(e) {
    elements = elements.not(e.target);
    if(tm) {
      window.clearTimeout(tm);
      tm = null;
    }

    tm = window.setTimeout(function() {
      if(elements.length === 0) {
        zone.removeClass('dragging');
      }
    }, 200);
  };

  zone.dropzone({
    createImageThumbnails: false,
    maxFilesize: cforum.imageMaxSize || 2, // default to 2mb
    filesizeBase: 1024,
    url: cforum.baseUrl + 'images.json',
    clickable: true,
    acceptedFiles: 'image/*',
    previewTemplate : '<div style="display:none"></div>',

    dictDefaultMessage: t('upload.dictDefaultMessage'),
    dictFallbackMessage: t("upload.dictFallbackMessage"),
    dictFallbackText: t("upload.dictFallbackText"),
    dictFileTooBig: t('upload.dictFileTooBig'),
    dictInvalidFileType: t("upload.dictInvalidFileType"),
    dictResponseError: t("upload.dictResponseError"),
    dictCancelUpload: t("upload.dictCancelUpload"),
    dictCancelUploadConfirmation: t("upload.dictCancelUploadConfirmation"),
    dictRemoveFile: t("upload.dictRemoveFile"),
    dictMaxFilesExceeded: t("upload.dictMaxFilesExceeded"),

    fallback: function() { },
    init: function() {
      this.on("success", function(file, rsp) {
        var modal = $("#md-img-upload-modal");
        modal.find("input").val("");

        zone.removeClass('loading dragging');
        zone.html(t('upload.image_area'));

        modal.modal({
          show: true,
          primaryAction: function() {
            modal.modal('hide');

            var selection = input.getSelection();
            var alt = $("#md-img-upload-desc").val();
            var title = $("#md-img-upload-title").val();

            var md = '[![' + alt + '](' + cforum.basePath + 'images/' + rsp.path + '?size=medium';
            if(title) {
              md += ' "' + title + '"';
            }
            md += ')](' + cforum.basePath + 'images/' + rsp.path + ')';

            input.replaceSelection(md);
            input.change();

            input.focus();
            input.setSelection(selection.start, selection.start + md.length);
          }
        });
      });

      this.on('error', function(file, response) {
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

        zone.removeClass('loading dragging');
        zone.html(t('upload.image_area'));
        cforum.alert.error(msg);
      });

      this.on('sending', function(file, xhr, formData) {
        zone.addClass('loading');
        zone.html("");

        xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'));
      });

      this.on('dragenter', enter);
      this.on('dragleave', leave);
    }
  });

  $(window).on('dragenter', enter);
  $(window).on('dragleave', leave);
}

/* eof */
