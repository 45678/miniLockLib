miniLockLib = module.exports = {}

# Construct and start a [key pair operation](MakeKeyPairOperation.html).
miniLockLib.makeKeyPair = (secretPhrase, emailAddress, callback) ->
  operation = new miniLockLib.MakeKeyPairOperation {secretPhrase, emailAddress}
  operation.start(callback)

# Construct and start an [encrypt operation](EncryptOperation.html).
miniLockLib.encrypt = (params, callback) ->
  operation = new miniLockLib.EncryptOperation params
  operation.start(callback)

# Construct and start a [decrypt operation](DecryptOperation.html).
miniLockLib.decrypt = (params, callback) ->
  operation = new miniLockLib.DecryptOperation params
  operation.start(callback)

# Supply [secret phrase](SecretPhrase.html) and [email address](EmailAddress.html) acceptance tests.
miniLockLib.SecretPhrase = require "./SecretPhrase"
miniLockLib.EmailAddress = require "./EmailAddress"

# Supply [identification](ID.html) function to encode, decode and test miniLock IDs.
miniLockLib.ID = require "./ID"

# Supply operation constructors.
miniLockLib.MakeKeyPairOperation = require "./MakeKeyPairOperation"
miniLockLib.EncryptOperation = require "./EncryptOperation"
miniLockLib.DecryptOperation = require "./DecryptOperation"

# Supply special extras.
miniLockLib.Base58  = require "./Base58"
miniLockLib.BLAKE2s = require "./BLAKE2s"
miniLockLib.NaCl    = require "./NaCl"
miniLockLib.scrypt  = require "./scrypt-async"
miniLockLib.zxcvbn  = require "./zxcvbn"
