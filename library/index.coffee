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
# `miniLockLib.makeKeyPair` is defined in Keys.coffee. Refer to that file for
# details about unacceptable secret phrases, unacceptable email addresses and
# other failure conditions.

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
#           error is undefined
#         else
#           error is a String explaing the failure
#           encrypted is undefined
#
# A `miniLockLib.EncryptOperation` is constructed when you call `encrypt`.
# Refer to EncryptOperation.coffee to see how it works.

miniLockLib.encrypt = (params, callback) ->
  params.callback = callback if callback
  params.start = yes
  new miniLockLib.EncryptOperation params




# --------------
# Decrypt a File
# --------------
#
#     miniLockLib.decrypt
#       data: File or Blob,
#       keys: {publicKey: Uint8Array, secretKey: Uint8Array}
#       callback: (error, decrypted) ->
#         if decrypted
#           decrypted.name is "alice_and_bobby.txt"
#           decrypted.data.constructor is Blob
#           decrypted.data.size.constructor is Number
#           decrypted.senderID is Alice.miniLockID
#           error is undefined
#         else
#           error is a String explaing the failure
#           encrypted is undefined
#
# A `miniLockLib.DecryptOperation` is constructed when you call `decrypt`.
# Refer to DecryptOperation.coffee to see how it works.

miniLockLib.decrypt = (params, callback) ->
  params.callback = callback if callback
  params.start = yes
  new miniLockLib.DecryptOperation params



miniLockLib.Base58 = Base58  = require("./Base58")
miniLockLib.BLAKE2 = BLAKE2  = require("./BLAKE2")
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
