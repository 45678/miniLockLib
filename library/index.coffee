miniLockLib = module.exports

# Start a [key pair operation](KeyPairOperation.html) to make a set of keys.
miniLockLib.makeKeyPair = (secretPhrase, emailAddress, callback) ->
  operation = new miniLockLib.KeyPairOperation {secretPhrase, emailAddress}
  operation.start(callback)

# Start an [encrypt operation](EncryptOperation.html) to make a miniLock file.
miniLockLib.encrypt = (params, callback) ->
  operation = new miniLockLib.EncryptOperation params
  operation.start(callback)

# Start a [decrypt operation](DecryptOperation.html) to unlock a miniLock file.
miniLockLib.decrypt = (params, callback) ->
  operation = new miniLockLib.DecryptOperation params
  operation.start(callback)

# Exports the [secret phrase](SecretPhrase.html) and
# [email address](EmailAddress.html) modules.
miniLockLib.SecretPhrase = require "./SecretPhrase"
miniLockLib.EmailAddress = require "./EmailAddress"

# Exports the [identification](ID.html) module.
miniLockLib.ID = require "./ID"

# Exports the miniLock crypto operation constructors.
miniLockLib.KeyPairOperation = require "./KeyPairOperation"
miniLockLib.EncryptOperation = require "./EncryptOperation"
miniLockLib.DecryptOperation = require "./DecryptOperation"

# Exports special extras.
miniLockLib.Base58     = require "./Base58"
miniLockLib.BLAKE2s    = require "./BLAKE2s"
miniLockLib.Entropizer = require "entropizer"
miniLockLib.NaCl       = require "./NaCl"
miniLockLib.scrypt     = require "./scrypt-async"
