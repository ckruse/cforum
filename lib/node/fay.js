/* -*- coding: utf-8 -*- */

var http = require('http'),
    faye = require('faye'),
    fs = require('fs');

var server = new faye.NodeAdapter({mount: '/faye', timeout: 45});
var publish_secret = fs.readFileSync('./config/faye.secret', {encoding: 'utf-8'});

server.addExtension({
  incoming: function(message, callback) {
    if (!message.channel.match(/^\/meta\//)) {
      var password = message.ext && message.ext.password;
      if(password !== publish_secret) {
        message.error = '403::Password required';
      }
    }

    callback(message);
  },

  outgoing: function(message, callback) {
    if(message.ext) {
      delete message.ext.password;
    }

    callback(message);
  }
});


if(fs.existsSync('./config/ssl.key') && fs.existsSync('./config/ssl.crt')) {
  server.listen(9091, {key: './config/ssl.key', cert: './config/ssl.crt'});
}
else {
  server.listen(9090);
}



// eof
