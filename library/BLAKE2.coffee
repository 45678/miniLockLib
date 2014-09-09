BLAKE2s = require("BLAKE2s")

# Thin wrapper around BLAKE2s with a more convenient API for our purposes.
module.exports = class BLAKE2 extends BLAKE2s
  constructor: (params) ->
    BLAKE2s.call(this, params.length)

  update: (input) ->
    BLAKE2s::update.call(this, input)
    return this
