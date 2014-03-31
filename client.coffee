Q = require 'q'

fs = require 'fs'

less       = require 'less'
handlebars = require 'handlebars'

render = (infos) ->
  parser = new less.Parser
  return Q.ninvoke parser, 'parse', fs.readFileSync('styles.less').toString('utf-8')
  .then (tree) ->
    styles = tree.toCSS()

    bodyTemplate = handlebars.compile fs.readFileSync('body.handlebars').toString('utf-8')
    htmlTemplate = handlebars.compile fs.readFileSync('html.handlebars').toString('utf-8')

    body = bodyTemplate { infos }
    html = htmlTemplate { body, styles }

    fs.writeFileSync 'static.html', html
    return # don't leak

module.exports = { render }
