/* -*- coding: utf-8 -*- */

var http = require('http'),
    faye = require('faye'),
    fs   = require('fs'),
    pg   = require('pg'),
    yaml = require('js-yaml');

var env = process.env.RAILS_ENV;

if(!env) {
  env = 'development';
}

var db_config = yaml.safeLoad(fs.readFileSync('config/database.yml', 'utf-8'))[env];

var conString = "postgres://";

if(db_config.username) {
  conString += db_config.username;
  if(db_config.password) {
    conString += ':' + db_config.password;
  }
  conString += "@";
}

if(db_config.host) {
  conString += db_config.host;
}
else {
  conString += "localhost";
}

conString += "/" + db_config.database;

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
        callback(message);
      }
    }

    if(message.channel == '/meta/subscribe' && message.subscription.match(/^\/user/)) {
      var token = message.ext && message.ext.token;
      var uid = message.subscription.substr(6).replace(/\/.*/, '');

      pg.connect(conString, function(err, client, done) {
        var handleError = function(err) {
          // no error occurred, continue with the request
          if(!err) {
            return false;
          }

          // An error occurred, remove the client from the connection pool.
          // A truthy value passed to done will remove the connection from the pool
          // instead of simply returning it to be reused.
          // In this case, if we have successfully received a client (truthy)
          // then it will be removed from the pool.
          if(client) {
            done(client);
          }

          message.error = "500::Server error";
          message.subscription = null;
          message.channel = null;

          return true;
        };

        if(handleError(err)) {
          callback(message);
          return;
        }

        client.query("SELECT websocket_token FROM users WHERE user_id = $1", [parseInt(uid, 10)], function(err, result) {
          if(handleError(err)) {
            callback(message);
            return;
          }

          done();

          if(!result.rows.length || !result.rows[0].websocket_token || result.rows[0].websocket_token != token) {
            message.error = '403::Password required';
            message.subscription = null;
            message.channel = null;
          }

          callback(message);
        });
      });
    }
    else {
      callback(message);
    }
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
