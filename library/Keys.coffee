BLAKE2  = require("./BLAKE2s")
NACL    = require("./NACL")
scrypt  = require("./scrypt-async")
zxcvbn  = require("./zxcvbn")

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
  switch
    when callback?.constructor isnt Function
      return "Can’t make a pair of keys without a callback function."
    when secretPhrase is undefined
      callback("Can’t make a pair of keys without a secret phrase.")
    when emailAddress is undefined
      callback("Can’t make a pair of keys without an email address.")
    when secretPhrase and emailAddress and callback
      # Decode each input into a Uint8Array of bytes.
      decodedSecretPhrase = NACL.util.decodeUTF8(secretPhrase)
      decodedEmailAddress = NACL.util.decodeUTF8(emailAddress)
      # Create a hash digest of the decoded secret phrase to increase its complexity.
      hashOfDecodedSecretPhrase = BLAKE2HashDigestOf(decodedSecretPhrase, length: 32)
      # Calculate keys for the hash of the secret phrase with email address as salt.
      calculateCurve25519KeyPair hashOfDecodedSecretPhrase, decodedEmailAddress, (keys) ->
        callback(undefined, keys)


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


# miniLock only accepts secret phrases that are at least 32 characters long and
# have at least 100 bits of entropy.
module.exports.secretPhraseIsAcceptable = (secretPhrase) ->
  secretPhrase?.length >= 32 and zxcvbn(secretPhrase).entropy >= 100


# miniLock only accepts relatively standards compliant email addresses.
module.exports.emailAddressIsAcceptable = (emailAddress) ->
  EmailAddressPattern.test(emailAddress)

EmailAddressPattern = /[-0-9A-Z.+_]+@[-0-9A-Z.+_]+\.[A-Z]{2,20}/i
