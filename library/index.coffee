miniLockLib = module.exports = {}

miniLockLib.Keys = require "./Keys"

# Make a set of Keys.
miniLockLib.makeKeyPair = (secretPhrase, emailAddress, callback) ->
  operation = new miniLockLib.MakeKeyPairOperation {secretPhrase, emailAddress}
  operation.start(callback)

# Encrypt a File.
miniLockLib.encrypt = (params, callback) ->
  operation = new miniLockLib.EncryptOperation params
  operation.start(callback)

# Decrypt a File.
miniLockLib.decrypt = (params, callback) ->
  operation = new miniLockLib.DecryptOperation params
  operation.start(callback)

# Export input modules.
miniLockLib.ID = require "./ID"
miniLockLib.EmailAddress = require "./EmailAddress"
miniLockLib.SecretPhrase = require "./SecretPhrase"

# Export miniLock crypto operation constructors.
miniLockLib.MakeKeyPairOperation = require("./MakeKeyPairOperation")
miniLockLib.EncryptOperation = require("./EncryptOperation")
miniLockLib.DecryptOperation = require("./DecryptOperation")

# Export special extras.
miniLockLib.Base58  = require("./Base58")
miniLockLib.BLAKE2s = require("./BLAKE2s")
miniLockLib.NaCl    = require("./NaCl")
miniLockLib.scrypt  = require("./scrypt-async")
miniLockLib.zxcvbn  = require("./zxcvbn")
