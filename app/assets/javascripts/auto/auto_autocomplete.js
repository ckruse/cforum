$(function() {
  $("input[data-autocomplete]").each(function() {
    var elem = $(this);
    var list = $("#" + elem.attr('data-autocomplete'));
    var data = list
      .find("option")
      .map(function(el) { return $(this).attr('value'); })
      .get();

    elem.autocomplete({
      source: function(request, response) {
        var results = $.ui.autocomplete.filter(data, request.term);
        response(results.slice(0, 5));
      },
      appendTo: elem.parent(),
      minLength: 0
    });

    elem.on('focus', function() { elem.autocomplete("search", ""); });
  });
});
