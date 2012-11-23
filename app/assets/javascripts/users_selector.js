cforum.common.usersSelector = $({});

cforum.common.usersSelector.selectedUsers = [];
cforum.common.usersSelector.foundUsers = [];

cforum.common.usersSelector.search = function(obj) {
  console.log(cforum.baseUrl)
  $.get(
    cforum.baseUrl + '/users.json',
    's=' + encodeURIComponent(obj.find(".user_search").val()),
    'json'
  ).
  success(function(data) {
    var sel = obj.find(".user-list");
    var the_html = "";

    cforum.common.usersSelector.foundUsers = [];

    for(var i = 0; i < data.length; ++i) {
      cforum.common.usersSelector.foundUsers[data[i].user_id] = data[i];
      the_html += Mustache.render(cforum.common.usersSelector.views.userFoundLine, data[i]);
    }

    sel.html(the_html);
    sel.find("li").fadeIn('fast');
  })
};

cforum.common.usersSelector.add = function(ev) {
  var $obj  = $(ev.target);
  var $sel  = $obj.closest(".users-selector");
  var found = $sel.find(".found-user-list");
  var uid   = $obj.attr('data-user-id');
  var uname = $obj.attr('data-username');

  var html  = Mustache.render(cforum.common.usersSelector.views.userAddLine, {user: {user_id: uid, username: uname}});

  if($sel.hasClass('single')) {
    found.html(html);
    cforum.common.usersSelector.selectedUsers = cforum.common.usersSelector.foundUsers[cid];
  }
  else {
    cforum.common.usersSelector.selectedUser[cid] = cforum.common.usersSelector.foundUsers[cid];
    found.append(html);
  }

  found.find("tr:last").fadeIn('fast');
};


cforum.common.usersSelector.select = function(event) {
  event.preventDefault();

  var $selector = $(this).closest(".users-selector");
  var found = $selector.find(".found-user-list");
  var $sel = $selector.find(".users");

  if($selector.hasClass('single')) {
    $sel.html("");
  }

  found.find("tr").each(function() {
    // $sel.append(
    //   '<label class="checkbox"><input type="checkbox" checked="checked" value="' +
    //   $(this).attr('data-contact-id') +
    //   '" name="' +
    //   $sel.attr('data-name') +
    //   '" id="' +
    //   $sel.attr("data-id") +
    //   '" onchange="cforum.common.usersSelector.unselectContact(this)">' + $(this).attr('data-display-name') + ", " + $(this).attr('data-address') +
    //   '</label>'
    // );
  });

  $(this).closest('.users-selector').find('.users-modal').modal('hide');
  cforum.common.usersSelector.trigger('users-selector:selected', [cforum.common.usersSelector.selectedUsers])
};

cforum.common.usersSelector.initiateSearch = function() {
  var $this = $(this);
  var tm = $this.data('timeout');
  if(tm) {
    window.clearTimeout(tm);
  }

  tm = window.setTimeout(function() {
    cforum.common.usersSelector.search($this.closest(".users-selector"));
  }, 1500);
  $this.data("timeout", tm);
};

cforum.common.usersSelector.init = function() {
  $(".users-selector .users-modal").modal({show: false});
  //TODO: $(".users-selector .del-user").click(function() { $(this).closest(".users-selector").find("select option:selected").remove(); });
  $(".users-selector .add-user").click(function() { $(this).closest(".users-selector").find(".users-modal").modal('show'); });
  //TODO: $(".users-selector").find("label.checkbox checkbox").click(function() { cforum.common.usersSelector.unselectUser(this); })
  $(".users-selector .cancel").click(function(event) {
    event.preventDefault();
    $(this).closest(".users-selector").find(".users-modal").modal('hide');
  });

  $(".users-selector .user_search").keyup(cforum.common.usersSelector.initiateSearch);
  $(".users-selector .ok").click(cforum.common.usersSelector.select);
};

cforum.common.usersSelector.views = {
  userFoundLine: '<li style="display:none"><i class="icon icon-plus" data-user-id="{{cf_user.user_id}}" data-username="{{cf_user.username}}"> </i> {{cf_user.username}}</li>',
  userAddLine: '<li style="display:none" data-user-id="{{user.user_id}}" data-username="{{user.username}}"><i class="icon icon-minus"> </i> {{user.username}}</li>'
};

$(document).ready(function() {
  cforum.common.usersSelector.init();
});

/* eof */