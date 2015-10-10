/* -*- coding: utf-8 -*- */
/* global require, process, console */

var app  = require('express')(),
    http = require('http').Server(app),
    fs   = require('fs'),
    pg   = require('pg'),
    yaml = require('js-yaml'),
    io   = require('socket.io')(http),
    bodyParser = require('body-parser');


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

var publish_secret = fs.readFileSync('./config/faye.secret', {encoding: 'utf-8'});

app.use(bodyParser.json());

app.post('/message', function(req, res) {
  // json structure is like that:
  // {secret: ..., event: <type>, for: 'all'|userid, data: ...}

  if(req.body.secret != publish_secret) {
    res.status(403).end();
    return;
  }

  if(req.body.for == 'all') {
    console.log("to:", "all", req.body.data);
    io.emit(req.body.event, req.body.data);
  }
  else {
    console.log("to:", req.body.for, req.body.data);
    io.to(req.body.for).emit(req.body.event, req.body.data);
  }

  res.status(201).end();
});

http.listen(9090, function() {
  console.log("Listening on :9090");
});

io.on('connection', function(socket) {
  socket.on('login', function(data) {
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

        return true;
      };

      if(handleError(err)) {
        return;
      }

      client.query("SELECT * FROM users WHERE user_id = $1", [data.user], function(err, result) {
        if(handleError(err)) {
          return;
        }

        done();

        if(!result.rows.length || !result.rows[0].websocket_token || result.rows[0].websocket_token != data.wstoken) {
          return;
        }

        socket.cforum = {authorized: true, user: result.rows[0]};
        socket.join("/users/" + data.user);
      });
    });
  });

  socket.on('join', function(data) {
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

        return true;
      };

      if(handleError(err)) {
        return;
      }

      if(!data.forum) {
        return;
      }

      // we join all forums when user is an admin
      if(socket.cforum && socket.cforum.user && socket.cforum.user.admin) {
        console.log("join", socket.cforum.user.username, '/forums/' + data.forum);
        socket.join('/forums/' + data.forum);
        return;
      }

      client.query("SELECT forum_id, standard_permission FROM forums WHERE slug = $1", [data.forum], function(err, result) {
        if(handleError(err) || result.rows.length == 0) {
          return;
        }

        var f = result.rows[0];

        if(f.standard_permission == 'read' || f.standard_permission == 'write' || f.standard_permission == 'moderate') {
          console.log("join", (socket.cforum && socket.cforum.user) ? socket.cforum.user.username : "anon", '/forums/' + data.forum);
          socket.join('/forums/' + data.forum);
          done();
        }
        else if((f.standard_permission == 'known-read' || f.standard_permission == 'known-write') && socket.cforum.authorized) {
          console.log("join", (socket.cforum && socket.cforum.user) ? socket.cforum.user.username : "anon", '/forums/' + data.forum);
          socket.join('/forums/' + data.forum);
          done();
        }
        else if(socket.cforum && socket.cforum.user) {
          client.query("SELECT permission FROM forums_groups_permissions LEFT JOIN groups_users USING(group_id) WHERE user_id = $1 AND forum_id = $2",
                       [socket.cforum.user.user_id, result.rows[0].forum_id],
                       function(err, result) {
                         if(handleError(err) || result.rows.length == 0) {
                           return;
                         }

                         done();

                         console.log("join", (socket.cforum && socket.cforum.user) ? socket.cforum.user.username : "anon", '/forums/' + data.forum);
                         socket.join('/forums/' + data.forum);
                       });
        }

      });

    });
  });
});



// eof
