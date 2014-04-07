_       = require 'lodash'
Q       = require 'q'
fs      = require 'fs'
winston = require 'winston'

less       = require 'less'
handlebars = require 'handlebars'

_canonicalizeForSorting = (s) ->
  s = s.toLowerCase()
  # Latinize?
  if s[0...4] == 'the '
    s = s[4..]
  else if s[0...2] == 'a '
    s = s[2..]
  return s

_alphabeticSort = (i1, i2) ->
  one = _canonicalizeForSorting i1.Title
  two = _canonicalizeForSorting i2.Title
  return switch
    when one < two then -1
    when one > two then 1
    else 0

_postProcessInfo = (info) ->
  parsedMetascore = parseInt info.Metascore, 10
  info.MetascoreCategory = switch
    when parsedMetascore < 41  then 'negative'
    when parsedMetascore < 61  then 'mixed'
    when parsedMetascore < 101 then 'positive'
    else 'unknown'

  info.AllGenres = _.map info.Genre.split(','), (g) -> g.trim()

  if info.Poster == 'N/A'
    info.Poster = null

  if info.Plot == 'N/A'
    info.Plot = null

  return # avoid implicti return -> early termination

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

      infos = infos.slice().sort _alphabeticSort
      _.each infos, _postProcessInfo

      body = bodyTemplate { infos }
      html = htmlTemplate { body, styles }

      return Q.ninvoke fs, 'writeFile', 'static.html', html

module.exports = { render }
