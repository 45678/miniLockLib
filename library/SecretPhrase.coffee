# An acceptable secret phrase is at least 32 characters long
# and has at least 200 bits of entropy according to `Entropizer`.

exports.isAcceptable = (secretPhrase) ->
  secretPhrase?.length >= 32 and entropizer.evaluate(secretPhrase) >= 200

Entropizer = require "entropizer"
entropizer = new Entropizer
