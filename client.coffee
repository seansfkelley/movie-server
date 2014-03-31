fs = require 'fs'

handlebars = require 'handlebars'

render = (infos) ->
  bodyTemplate = handlebars.compile fs.readFileSync('body.handlebars').toString('utf-8')
  htmlTemplate = handlebars.compile fs.readFileSync('html.handlebars').toString('utf-8')

  body = bodyTemplate { infos }
  html = htmlTemplate { body }

  fs.writeFileSync 'static.html', html

  return

module.exports = { render }
