/* -* coding: utf-8 -*- */
/* global cforum, t */

cforum.uploadFile = function(fileInput, success, failure) {
  var files = fileInput.files;
  if(files.length <= 0) {
    if(failure) {
      failure(null, t("uploads.no_image_given"));
    }
    return;
  }

  var file = files[0];

  if(!file.type.match('image.*')) {
    if(failure) {
      failure(null, t("uploads.no_image_given"));
    }
    return;
  }

  var formData = new FormData();
  formData.append('file', file, file.name);

  $.ajax({
    url: cforum.baseUrl + 'images',
    data: formData,
    processData: false,
    contentType: false,
    type: 'POST'
  })
    .done(success)
    .fail(failure);
};


/* eof */
