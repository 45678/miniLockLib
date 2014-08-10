BLAKE2  = require("./BLAKE2")
NACL    = require("./NACL")
scrypt  = require("./scrypt-async")
zxcvbn  = require("./zxcvbn")

# Make a set of keys for a secret phrase and email address. Your `callback`
# receives a pair of `keys`, or an `error`, like this:
#
#     miniLockLib.makeKeyPair secretPhrase, emailAddress, (error, keys) ->
#        if keys?
#          keys.publicKey is a Uint8Array
#          keys.secretKey is a Uint8Array
#          error is undefined
#        else
#          error is a String explaining the failure
#          keys in undefined
#
# The secret phrase and email address are both tested to make sure they meet
# miniLock’s standards. The phrase must be at least 32 characters long and it
# must contain at least 100 bits of entropy. The address musn’t be invalid. If
# either input is unacceptable your `callback` will receive an explanation of
# the failure as its `error` argument.
#
# Making a pair of keys will take a few seconds — please be patient.

exports.makeKeyPair = (secretPhrase, emailAddress, callback) ->
  switch
    when callback?.constructor isnt Function
      return "Can’t make a pair of keys without a callback function."
    when secretPhrase is undefined
      callback "Can’t make a pair of keys without a secret phrase."
    when exports.secretPhraseIsAcceptable(secretPhrase) is no
      callback "Can’t make a pair of keys because the secret phrase is unacceptable."
    when emailAddress is undefined
      callback "Can’t make a pair of keys without an email address."
    when exports.emailAddressIsAcceptable(emailAddress) is no
      callback "Can’t make a pair of keys because the email address is unacceptable."
    when secretPhrase and emailAddress and callback
      # Decode each input into a Uint8Array of bytes.
      decodedSecretPhrase = NACL.util.decodeUTF8(secretPhrase)
      decodedEmailAddress = NACL.util.decodeUTF8(emailAddress)
      # Create a hash digest of the decoded secret phrase to increase its complexity.
      hashDigestOfDecodedSecretPhrase = (new BLAKE2 length: 32).update(decodedSecretPhrase).digest()
      # Calculate keys for the hash of the secret phrase with email address as salt.
      calculateCurve25519KeyPair hashDigestOfDecodedSecretPhrase, decodedEmailAddress, (keys) ->
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


# miniLock only accepts secret phrases that are at least 32 characters long and
# have at least 100 bits of entropy.
exports.secretPhraseIsAcceptable = (secretPhrase) ->
  secretPhrase?.length >= 32 and zxcvbn(secretPhrase).entropy >= 100


# miniLock only accepts relatively standards compliant email addresses.
exports.emailAddressIsAcceptable = (emailAddress) ->
  EmailAddressPattern.test(emailAddress)

EmailAddressPattern = /[-0-9A-Z.+_]+@[-0-9A-Z.+_]+\.[A-Z]{2,20}/i
