/* -*- coding: utf-8 -*- */

$(document).ready(function() {
  var targetlist = '<nav><ul class="tabswitcher"></ul></nav>', targets = '';
  $('.cf-tab-content').prepend(targetlist);
  $('.cf-tab-pane').each(function(){
    targets += '<li><a href="#' + this.id + '">' + $(this).children('legend').text() + '</a></li>';
  });

  $('.tabswitcher').append(targets);
  $("body").addClass("tabs-active");

  var hash = document.location.hash;
  if(!hash && history.pushState) {
    var first = $(".tabswitcher li a:first");
    hash = first.attr("href");
    history.pushState({}, first.text(), hash);
  }

  $(hash).addClass('active');
  $('.tabswitcher a[href="' + hash + '"]').parent().addClass("active");

  $('.tabswitcher li a').on('click', function(ev) {
    ev.preventDefault();
    $(".cf-tab-pane.active").removeClass("active");
    $(".tabswitcher .active").removeClass("active");

    var anchor = $(this).attr("href");
    $(anchor).addClass("active");
    $(this).parent().addClass("active");

    if(history.pushState) {
      history.pushState({}, $(this).text(), anchor);
    }
  });

  $(window).on('popstate', function() {
    var anchor = document.location.hash || $(".tabswitcher li a:first").attr("href");

    $(".cf-tab-pane.active").removeClass("active");
    $(".tabswitcher .active").removeClass("active");

    $(anchor).addClass("active");
    $('.tabswitcher a[href="' + anchor + '"]').parent().addClass("active");
  });
});

/* eof */
