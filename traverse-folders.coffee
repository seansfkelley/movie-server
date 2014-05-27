_        = require 'lodash'
fs       = require 'fs'
path     = require 'path'

unorm    = require 'unorm'
latinize = require './latinize'

MOVIE_FILETYPES = [
  '.avi'
  '.mkv'
  '.mov'
  '.mp4'
]

_firstIndexOfAny = (string, regexes) ->
  return _.chain regexes
    .map (r) -> string.search(r)
    .filter (i) -> i > -1
    .tap (array) -> if not array.length then array.push(-1)
    .min()
    .value()

# These generally appear after the title.
TRUNCATE_TOKENS = [
  /[\[\(\{]/
  /dvd(scr|rip)?|xvid|divx/i
  /\d{4}/
  /s\d{2}e\d{2}/i
  /(720|1080)p/i
  /hdtv/i
  /director's cut/i
  /blu-?ray/i
]
_truncateAfterPointlessTokens = (s) ->
  i = _firstIndexOfAny s, TRUNCATE_TOKENS
  if i == -1
    i = s.length
  return s.slice 0, i

# These sometimes appear in the middle of titles (between show and episode names).
DROP_TOKENS = [
  /season.\d{1,}(.complete)?/i
  /episode.\d{1,}/i
  /\D\d{1,3}-\d{1,3}\D(complete)?/i # {1,3} because 4-digit numbers might be years in the title.
]
_dropOtherPointlessTokens = (s) ->
  for t in DROP_TOKENS
    s = s.replace t, ''
  return s

# This is fucking unreadable.
# Find all string-initial, whitespace-separated pairings of any of [({ with any of })].
INTIAL_BRACKETED_REGEX = /^(\s*[\[\(\{][^\]\)\}]*[\]\)\}])*\s*/
_sanitizeFilename = (basename) ->
  normalized =
    _dropOtherPointlessTokens(
      _truncateAfterPointlessTokens(
        basename.replace INTIAL_BRACKETED_REGEX, ''
      )
    )
    .replace /[-.]/g, ' '
    .replace /\s{2,}/g, ' '
    .trim()
    .normalize 'NFKC' # from unorm
  return latinize normalized

# Note that this only searches one level.
_directoryContainsMovies = (dir) ->
  return _.chain(fs.readdirSync(dir))
    .map((f) -> path.extname(f) in MOVIE_FILETYPES)
    .any()
    .value()

_checkFileOrDirectory = (parent) -> (p) ->
  return null if p[0] == '.'
  fullPath = path.join(parent, p)

  stats = fs.statSync(fullPath)
  if stats.isFile() and path.extname(p) in MOVIE_FILETYPES
    basename = path.basename(p, path.extname(p))
    return {
      sanitized : _sanitizeFilename basename
      basename  : basename
    }
  else if stats.isDirectory() and _directoryContainsMovies fullPath
    return {
      sanitized : _sanitizeFilename p
      basename  : p
    }
  else
    return null

_findSingle = (dir) ->
  if not fs.existsSync dir
    return []
  else
    return _.chain fs.readdirSync(dir)
      .map _checkFileOrDirectory(dir)
      .compact()
      .value()

findMoviesIn = (directories...) ->
  return _.chain directories
    .map _findSingle
    .flatten()
    .sortBy('sanitized')
    .uniq('sanitized')
    .value()

module.exports = { findMoviesIn }
