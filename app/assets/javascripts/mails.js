cforum.mails = {
  index: function() {
    $("#check-all-box").on('change', function() {

      if($(this).is(":checked")) {
        $(".mid-checkbox").attr("checked","checked");
      }
      else {
        $(".mid-checkbox").removeAttr('checked');
      }

    });
  }
}

/* eof */