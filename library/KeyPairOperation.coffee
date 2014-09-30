module.exports = class KeyPairOperation
  BLAKE2s = require "./BLAKE2s"
  NaCl = require "./NaCl"
  scrypt = require "./scrypt-async"

  EmailAddress = require "./EmailAddress"
  SecretPhrase = require "./SecretPhrase"

  constructor: (params) ->
    {@secretPhrase, @emailAddress} = params

  # Decode secret phrase input string into a `Uint8Array` of bytes.
  secret: ->
    NaCl.util.decodeUTF8(@secretPhrase)

  # Decode email address input string into a `Uint8Array` of bytes.
  salt: ->
    NaCl.util.decodeUTF8(@emailAddress)

  # Hash digest of the `secret()` to increase its potential complexity.
  hashDigestOfSecret: ->
    (new BLAKE2s length: 32).update(@secret()).digest()

  # Start the operation.
  # `callback` receives `error` or `keys` when the operation is complete.
  start: (callback) ->
    switch
      when callback?.constructor isnt Function
        return "Can’t make keys without a callback function."
      when @secretPhrase is undefined
        callback "Can’t make keys without a secret phrase."
      when SecretPhrase.isAcceptable(@secretPhrase) is no
        callback "Can’t make keys because '#{@secretPhrase}' is not an acceptable secret phrase."
      when @emailAddress is undefined
        callback "Can’t make keys without an email address."
      when EmailAddress.isAcceptable(@emailAddress) is no
        callback "Can’t make keys because '#{@emailAddress}' is not an acceptable email address."
      when @secretPhrase and @emailAddress and callback
        calculateCurve25519KeyPair @hashDigestOfSecret(), @salt(), (keys) ->
          callback(undefined, keys)

  # Calculate a curve25519 key pair for the given `secret` and `salt`.
  calculateCurve25519KeyPair = (secret, salt, callback) ->
    whenKeysAreReady = (encodedBytes) ->
      decodedBytes = NaCl.util.decodeBase64(encodedBytes)
      keys = NaCl.box.keyPair.fromSecretKey(decodedBytes)
      callback(keys)
    logN          = 17       # CPU/memory cost parameter (1 to 31).
    r             = 8        # Block size parameter. (I don’t know about this).
    dkLen         = 32       # Length of derived keys. (A miniLock key is 32 numbers).
    interruptStep = 1000     # Steps to split calculation with timeouts (default 1000).
    encoding      = "base64" # Output encoding ("base64", "hex", or null).
    scrypt(secret, salt, logN, r, dkLen, interruptStep, whenKeysAreReady, encoding)
