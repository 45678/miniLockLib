Base58  = this.Base58
BLAKE2s = this.BLAKE2s
nacl    = this.nacl
scrypt  = this.scrypt
zxcvbn  = this.zxcvbn

miniLockLib = this.miniLockLib = {}


# --------------
# Secret Phrases
# --------------
#
# miniLock only accepts secret phrases that are at least 32 characters long 
# and have at least 100 bits of entropy.
#
miniLockLib.secretPhraseIsAcceptable = (secretPhrase) ->
  secretPhrase?.length >= 32 and zxcvbn(secretPhrase).entropy >= 100




# ---------------
# Email Addresses
# ---------------
#
# miniLock only accepts relatively standards compliant email addresses.
#
miniLockLib.emailAddressIsAcceptable = (emailAddress) ->
  EmailAddressPattern.test(emailAddress)

EmailAddressPattern = /[-0-9A-Z.+_]+@[-0-9A-Z.+_]+\.[A-Z]{2,20}/i




# -------------
# miniLock Keys
# -------------
#
# miniLock key pairs consist of two cryptographic keys (two lists of numbers 
# between 0..255, each list has 32 numbers in it). Your public key lets you 
# encrypt your own files and it lets other people encrypt files for you. Your 
# secret key unlocks files that were encrypted for you. Both keys are derived 
# from the combination your secret phrase and email address. Your email address
# acts as the key derivation salt to ensure your key pair is unique just in 
# case someone else uses the same secret phrase as you do.
#
# Call `miniLockLib.getKeyPair` to generate a set of keys from a secret phrase 
# and email address. Your `callback` receives a pair of `keys` like this:
#
#     miniLockLib.getKeyPair secretPhrase, emailAddress, (keys) ->
#        keys.publicKey is a Uint8Array
#        keys.secretKey is a Uint8Array
#
miniLockLib.getKeyPair = (secretPhrase, emailAddress, callback) ->
  # Decode each input into a Uint8Array of bytes.
  decodedSecretPhrase = nacl.util.decodeUTF8(secretPhrase)
  decodedEmailAddress = nacl.util.decodeUTF8(emailAddress)
  
  # Create a hash digest of the decoded secret phrase.
  # (Why? Because the miniLock specification says so.)
  hashOfDecodedSecretPhrase = BLAKE2HashDigest(decodedSecretPhrase, length: 32)
  
  # Calculate keys for the hash of the secret phrase and email address salt.
  calculateCurve25519Keys hashOfDecodedSecretPhrase, decodedEmailAddress, callback


# Calculate a curve25519 key pair for the given `secret` and `salt`.
calculateCurve25519Keys = (secret, salt, callback) ->
  # Decode and unpack the keys when the task is complete.
  whenKeysAreReady = (encodedBytes) ->
    decodedBytes = nacl.util.decodeBase64(encodedBytes)
    keys = nacl.box.keyPair.fromSecretKey(decodedBytes)
    callback(keys)
  
  # Define miniLock `scrypt` parameters for the calculation task:
  logN          = 17       # CPU/memory cost parameter (1 to 31).
  r             = 8        # Block size parameter. (I don’t know about this).
  dkLen         = 32       # Length of derived keys. (A miniLock key is 32 numbers).
  interruptStep = 1000     # Steps to split calculation with timeouts (default 1000).
  encoding      = "base64" # Output encoding ("base64", "hex", or null).
  
  # Send the task to `scrypt` for processing...
  scrypt(secret, salt, logN, r, dkLen, interruptStep, whenKeysAreReady, encoding)




# ------------
# miniLock IDs
# ------------

miniLockLib.ID = {}

# Returns `true` if `id` is acceptable and `false` if it is not.
miniLockLib.ID.isAcceptable = (id) ->
  /^[1-9A-Za-z]{40,55}$/.test(id) and miniLockLib.ID.decode(id)?

# Encode a 32-bit public key as a miniLockID.
miniLockLib.ID.encode = (publicKey) ->
  if publicKey?.length is 32
    slots = new Uint8Array(33)
    slots[index] = publicKey[index] for index in [0..32]
    slots[32] = BLAKE2HashDigest(publicKey, length: 1)[0]
    Base58.encode(slots)
  else
    undefined

# Decode a 32-bit public key from a miniLockID.
miniLockLib.ID.decode = (id) ->
  slots = Base58.decode(id)
  if slots.length is 33
    publicKey = slots.subarray(0, 32)
    encodedChecksum = slots[32]
    trueChecksum = BLAKE2HashDigest(publicKey, length: 1)[0]
    return publicKey if encodedChecksum is trueChecksum
  undefined




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

# Convert a Number to a 4-byte little-endian Uint8Array
miniLockLib.numberToByteArray = (n) ->
  byteArray = new Uint8Array(4)
  for index in [0..4]
    byteArray[index] = n & 255
    n = n >> 8
  byteArray

# Convert a 4-byte little-endian Uint8Array to a Number
miniLockLib.byteArrayToNumber = (byteArray) ->
  n = 0
  for index in [3..0]
    n += byteArray[index]
    if (index isnt 0)
      n = n << 8
  return n

# Construct a BLAKE2 hash digest of `input`. Specify digest `length` as a `Number`.
BLAKE2HashDigest = (input, options={}) ->
  hash = new BLAKE2s(options.length)
  hash.update(input)
  hash.digest()

