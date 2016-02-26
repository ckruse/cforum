/* -* coding: utf-8 -*- */

$(function() {
  $("[data-cf-confirm]").on('click', function(event) {
    var $this = $(this);
    if($this.hasClass('is-confirmed')) {
      return;
    }

    event.preventDefault();
    event.stopPropagation();

    $this.addClass("is-confirmed cf-primary-btn");
    $this.removeClass('cf-btn');
    $this.text(" " + $this.attr('data-cf-confirm'));
  });
});

/* eof */
