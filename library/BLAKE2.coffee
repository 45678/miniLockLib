BLAKE2s = require("./BLAKE2s")

# Thin wrapper around BLAKE2s with a more convenient API for our purposes.
module.exports = class BLAKE2
  constructor: (params) ->
    @delegate = new BLAKE2s(params.length)

  update: (input) ->
    @delegate.update(input)
    return this

  digest: ->
    @delegate.digest()
