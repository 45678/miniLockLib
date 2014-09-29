miniLockLib = module.exports = {}

# Make a set of keys.
miniLockLib.makeKeyPair = (secretPhrase, emailAddress, callback) ->
  operation = new miniLockLib.MakeKeyPairOperation {secretPhrase, emailAddress}
  operation.start(callback)

# Encrypt a file.
miniLockLib.encrypt = (params, callback) ->
  operation = new miniLockLib.EncryptOperation params
  operation.start(callback)

# Decrypt a file.
miniLockLib.decrypt = (params, callback) ->
  operation = new miniLockLib.DecryptOperation params
  operation.start(callback)

# Acceptance tests for key pair inputs.
miniLockLib.SecretPhrase = require "./SecretPhrase"
miniLockLib.EmailAddress = require "./EmailAddress"

# Encode, decode and test identification.
miniLockLib.ID = require "./ID"

# miniLock crypto operations.
miniLockLib.MakeKeyPairOperation = require "./MakeKeyPairOperation"
miniLockLib.EncryptOperation = require "./EncryptOperation"
miniLockLib.DecryptOperation = require "./DecryptOperation"

# Export special extras.
miniLockLib.Base58  = require "./Base58"
miniLockLib.BLAKE2s = require "./BLAKE2s"
miniLockLib.NaCl    = require "./NaCl"
miniLockLib.scrypt  = require "./scrypt-async"
miniLockLib.zxcvbn  = require "./zxcvbn"
