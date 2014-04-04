Q       = require 'q'
fs      = require 'fs'
winston = require 'winston'

less       = require 'less'
handlebars = require 'handlebars'

render = (infos) ->
  return Q.ninvoke fs, 'readFile', 'styles.less'
    .then (styles) ->
      winston.debug 'read styles file'
      parser = new less.Parser
      return Q.all [
        Q.ninvoke parser, 'parse', styles.toString('utf-8')
        Q.ninvoke fs, 'readFile', 'body.handlebars'
        Q.ninvoke fs, 'readFile', 'html.handlebars'
      ]
    .spread (tree, body, html) ->
      winston.debug 'parsed styles, read body + html'
      styles = tree.toCSS()
      bodyTemplate = handlebars.compile body.toString('utf-8')
      htmlTemplate = handlebars.compile html.toString('utf-8')

      body = bodyTemplate { infos }
      html = htmlTemplate { body, styles }

      return Q.ninvoke fs, 'writeFile', 'static.html', html

module.exports = { render }
