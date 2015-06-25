<<<<<<< HEAD
// Generated by CoffeeScript 1.8.0
=======
// Generated by CoffeeScript 1.9.1
>>>>>>> built
var americano, publicPath, publicStatic, staticMiddleware;

americano = require('americano');

publicPath = "" + __dirname + "/../client/public";

staticMiddleware = americano["static"](publicPath, {
  maxAge: 86400000
});

publicStatic = function(req, res, next) {
  var assetsMatched, detectAssets;
  detectAssets = /\/(stylesheets|javascripts|images|fonts)+\/(.+)$/;
  assetsMatched = detectAssets.exec(req.url);
  if (assetsMatched != null) {
    req.url = assetsMatched[0];
  }
  return staticMiddleware(req, res, function(err) {
    return next(err);
  });
};

module.exports = {
  common: {
    use: [
      staticMiddleware, publicStatic, americano.bodyParser({
        keepExtensions: true
      })
    ],
    afterStart: function(app, server) {
      return app.use(americano.errorHandler({
        dumpExceptions: true,
        showStack: true
      }));
    },
    set: {
      views: './client'
    },
    engine: {
      js: function(path, locales, callback) {
        return callback(null, require(path)(locales));
      }
    }
  },
  development: [americano.logger('dev')],
  production: [americano.logger('short')],
  plugins: ['cozydb']
};
