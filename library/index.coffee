miniLockLib = module.exports = {}

miniLockLib.Keys             = require "./Keys"
miniLockLib.ID               = require "./ID"
miniLockLib.EncryptOperation = require("./EncryptOperation")
miniLockLib.DecryptOperation = require("./DecryptOperation")

miniLockLib.Base58 = Base58  = require("./Base58")
miniLockLib.BLAKE2 = BLAKE2  = require("./BLAKE2s")
miniLockLib.NACL   = NACL    = require("./NACL")
miniLockLib.scrypt = scrypt  = require("./scrypt-async")
miniLockLib.zxcvbn = zxcvbn  = require("./zxcvbn")



# -------------
# miniLock Keys
# -------------
#
# Call `miniLockLib.makeKeyPair` to generate a set of keys from a secret phrase
# and email address. Your `callback` receives a pair of `keys` like this:
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
miniLockLib.makeKeyPair = miniLockLib.Keys.makeKeyPair




# -------
# Encrypt
# -------
#
#     miniLockLib.encrypt
#       data: blob,
#       name: "alice_and_bobby.txt"
#       keys: {publicKey: Uint8Array, secretKey: Uint8Array}
#       miniLockIDs: [Alice.miniLockID, Bobby.miniLockID]
#       callback: (error, encrypted) ->
#         error is undefined or it is a message String
#         encrypted.name is "alice_and_bobby.txt.minilock"
#         encrypted.data.constructor is Blob
#         encrypted.data.size.constructor is Number
#         encrypted.senderID is Alice.miniLockID
#
miniLockLib.encrypt = (params) ->
  {data, name, miniLockIDs, keys, callback} = params
  new miniLockLib.EncryptOperation
    data: data
    name: name
    keys: keys
    miniLockIDs: miniLockIDs
    saveName: name+".minilock"
    callback: callback
    start: yes




# -------
# Decrypt
# -------
#
#     miniLockLib.decrypt
#       data: blob,
#       keys: {publicKey: Uint8Array, secretKey: Uint8Array}
#       callback: (error, decrypted) ->
#         error is undefined or it is a message String
#         decrypted.name is "alice_and_bobby.txt"
#         decrypted.data.constructor is Blob
#         decrypted.data.size.constructor is Number
#         decrypted.senderID is Alice.miniLockID
#
miniLockLib.decrypt = (params) ->
  {data, keys, callback} = params
  new miniLockLib.DecryptOperation
    data: data
    keys: keys
    callback: callback
    start: yes




# Explanations of miniLock’s numeric error codes.
miniLockLib.ErrorMessages =
  # Encryption errors
  1: "General encryption error"
  # Decryption errors
  2: "General decryption error"
  3: "Could not parse header"
  4: "Invalid header version"
  5: "Could not validate sender ID"
  6: "File is not encrypted for this recipient"
  7: "Could not validate ciphertext hash"
