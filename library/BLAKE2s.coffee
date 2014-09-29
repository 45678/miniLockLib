OriginalBLAKE2s = require "blake2s-js"

# Thin wrapper around BLAKE2s with a more convenient API for our purposes.
module.exports = class BLAKE2s extends OriginalBLAKE2s
  constructor: (params) ->
    OriginalBLAKE2s.call(this, params.length)

  update: (input) ->
    OriginalBLAKE2s::update.call(this, input)
    return this
