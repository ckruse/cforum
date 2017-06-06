/* -*- coding: utf-8 -*- */

/* global cforum, t */

function ImageUpload(input) {
  input.after('<div class="image-upload">' + t('upload.image_area') + '</div>');
  var zone = input.next('.image-upload');

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
        var selection = input.getSelection();
        var md = '[![' + t('upload.alternative_text') + '](' + cforum.basePath + 'images/' + rsp.path + '?size=medium)](' + cforum.basePath + 'images/' + rsp.path + ')';

        zone.removeClass('loading');
        zone.html(t('upload.image_area'));

        input.replaceSelection(md);
        input.change();

        window.setTimeout(function() {
          input.focus();
          input.setSelection(selection.start + 3, selection.start + 18);
        }, 0);
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

        zone.removeClass('loading');
        zone.html(t('upload.image_area'));
        cforum.alert.error(msg);
      });

      this.on('sending', function(file, xhr, formData) {
        zone.addClass('loading');
        zone.html("");

        xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'));
      });
    }
  });
}

/* eof */
