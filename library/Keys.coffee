BLAKE2  = require("./BLAKE2s")
NACL    = require("./NACL")
scrypt  = require("./scrypt-async")

# -------------
# miniLock Keys
# -------------

# Make a set of keys for the given `secretPhrase` and `emailAddress`.
# Your `callback` receives a pair keys like this:
#
#     miniLockLib.Keys.makeKeyPair secretPhrase, emailAddress, (keys) ->
#        keys.publicKey is a Uint8Array
#        keys.secretKey is a Uint8Array
#
module.exports.makeKeyPair = (secretPhrase, emailAddress, callback) ->
  # Decode each input into a Uint8Array of bytes.
  decodedSecretPhrase = NACL.util.decodeUTF8(secretPhrase)
  decodedEmailAddress = NACL.util.decodeUTF8(emailAddress)

  # Create a hash digest of the decoded secret phrase.
  hashOfDecodedSecretPhrase = BLAKE2HashDigestOf(decodedSecretPhrase, length: 32)

  # Calculate keys for the hash of the secret phrase and email address salt.
  calculateCurve25519KeyPair hashOfDecodedSecretPhrase, decodedEmailAddress, callback


# Calculate a curve25519 key pair for the given `secret` and `salt`.
calculateCurve25519KeyPair = (secret, salt, callback) ->
  # Decode and unpack the keys when the task is complete.
  whenKeysAreReady = (encodedBytes) ->
    decodedBytes = NACL.util.decodeBase64(encodedBytes)
    keys = NACL.box.keyPair.fromSecretKey(decodedBytes)
    callback(keys)

  # Define miniLock `scrypt` parameters for the calculation task:
  logN          = 17       # CPU/memory cost parameter (1 to 31).
  r             = 8        # Block size parameter. (I don’t know about this).
  dkLen         = 32       # Length of derived keys. (A miniLock key is 32 numbers).
  interruptStep = 1000     # Steps to split calculation with timeouts (default 1000).
  encoding      = "base64" # Output encoding ("base64", "hex", or null).

  # Send the task to `scrypt` for processing...
  scrypt(secret, salt, logN, r, dkLen, interruptStep, whenKeysAreReady, encoding)


# Construct a BLAKE2 hash digest of `input`. Specify digest `length` as a `Number`.
BLAKE2HashDigestOf = (input, options={}) ->
  hash = new BLAKE2(options.length)
  hash.update(input)
  hash.digest()
