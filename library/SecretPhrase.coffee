# An acceptable secret phrase is at least 32 characters long
# and has at least 100 bits of entropy according to `zxcvbn`.

exports.isAcceptable = (secretPhrase) ->
  secretPhrase?.length >= 32 and zxcvbn(secretPhrase).entropy >= 100

zxcvbn = require "./zxcvbn"
