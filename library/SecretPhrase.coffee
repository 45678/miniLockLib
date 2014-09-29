zxcvbn  = require "./zxcvbn"

# An acceptable secret phrases is at least 32 characters long and has at least 100 bits of entropy.
exports.isAcceptable = (secretPhrase) ->
  secretPhrase?.length >= 32 and zxcvbn(secretPhrase).entropy >= 100
