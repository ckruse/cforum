/* -*- coding: utf-8 -*- */

var http = require('http'),
    faye = require('faye'),
    fs   = require('fs'),
    pg   = require('pg-sync'),
    yaml = require('js-yaml');

var env = process.env.RAILS_ENV;

if(!env) {
  env = 'development';
}

var db_config = yaml.safeLoad(fs.readFileSync('config/database.yml', 'utf-8'))[env];

var conString = "";

if(db_config.username) {
  conString += "user=" + db_config.username;
  if(db_config.password) {
    conString += ' password=' + db_config.password;
  }
}

if(db_config.host) {
  conString += " host=" + db_config.host;
}
else {
  conString += " host=localhost";
}

conString += " dbname=" + db_config.database;

var client = new pg.Client();
client.connect(conString);


if(db_config.schema_search_path) {
  client.query("SET search_path = " + db_config.schema_search_path + ", public");
}

var http_server = http.createServer(function(request, response) {
  var body = "Could not be found.";
  response.writeHead(404, {
    'Content-Length': body.length,
    'Content-Type': 'text/plain'
  });

  response.write(body);
  response.end();
});
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

    if(message.channel == '/meta/subscribe' && message.subscription.match(/^\/user/)) {
      var token = message.ext && message.ext.token;
      var uid = message.subscription.substr(6).replace(/\/.*/, '');

      var rs = client.query("SELECT websocket_token FROM users WHERE user_id = $1", [parseInt(uid, 10)]);
      if(!rs || !rs.length || !rs[0].websocket_token || rs[0].websocket_token != token) {
        message.error = '403::Password required';
        message.subscription = null;
        message.channel = null;
      }
    }

    callback(message);
  },

  outgoing: function(message, callback) {
    if(message.ext) {
      delete message.ext.password;
      delete message.ext.token;
    }

    callback(message);
  }
});

server.attach(http_server);

if(fs.existsSync('./config/ssl.key') && fs.existsSync('./config/ssl.crt')) {
  http_server.listen(9091, {key: './config/ssl.key', cert: './config/ssl.crt'});
}
else {
  http_server.listen(9090);
}





// eof
