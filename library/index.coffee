miniLockLib = module.exports = {}

miniLockLib.Keys             = require "./Keys"
miniLockLib.ID               = require "./ID"
miniLockLib.EncryptOperation = require("./EncryptOperation")
miniLockLib.DecryptOperation = require("./DecryptOperation")

# ------------------
# Make a set of Keys
# ------------------
#
# Call `miniLockLib.makeKeyPair` to generate a set of keys from a secret phrase
# and email address. Your `callback` receives a pair of `keys` like this:
#
#   miniLockLib.makeKeyPair secretPhrase, emailAddress, (error, keys) ->
#    if keys
#      keys.publicKey is a Uint8Array
#      keys.secretKey is a Uint8Array
#      error is undefined
#    else
#      error is a String explaining the failure
#      keys is undefined
#
# `miniLockLib.makeKeyPair` tests the secret phrase and email address to make
# sure they meet miniLock’s standards. The secret phrase must be at least 32
# characters long and it must contain at least 100 bits of entropy. The email
# address must be valid. If either input is unacceptable your callback will
# receive an error.
#
# `miniLockLib.makeKeyPair` is defined in Keys.coffee. Refer to that file for
# more details and references to all its error messages.
miniLockLib.makeKeyPair = miniLockLib.Keys.makeKeyPair



# --------------
# Encrypt a File
# --------------
#
#     miniLockLib.encrypt
#       data: File or Blob,
#       name: "alice_and_bobby.txt"
#       keys: {publicKey: Uint8Array, secretKey: Uint8Array}
#       miniLockIDs: [Alice.miniLockID, Bobby.miniLockID]
#       callback: (error, encrypted) ->
#         if encrypted
#           encrypted.name is "alice_and_bobby.txt.minilock"
#           encrypted.data is a Blob
#           encrypted.data.size is Number
#           encrypted.senderID is Alice.miniLockID
#           encrypted.duration is in Milliseconds
#           error is undefined
#         else
#           error is a String explaing the failure
#           encrypted is undefined
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




# --------------
# Decrypt a File
# --------------
#
#     miniLockLib.decrypt
#       data: File or Blob,
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




miniLockLib.Base58 = Base58  = require("./Base58")
miniLockLib.BLAKE2 = BLAKE2  = require("./BLAKE2s")
miniLockLib.NACL   = NACL    = require("./NACL")
miniLockLib.scrypt = scrypt  = require("./scrypt-async")
miniLockLib.zxcvbn = zxcvbn  = require("./zxcvbn")

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
