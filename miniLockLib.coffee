Base58  = this.Base58
BLAKE2s = this.BLAKE2s
nacl    = this.nacl
scrypt  = this.scrypt
zxcvbn  = this.zxcvbn

miniLockLib = this.miniLockLib = {}


# -----
# Setup
# -----
#
# Set `miniLockLib.pathToScripts` to the location of the miniLockLib scripts
# on your web host. This path is required to resolve `miniLockCryptoWorker.js` 
# when a worker is created durring `encrypt` and `decrypt`.
#
miniLockLib.pathToScripts = '.'


# --------------
# Secret Phrases
# --------------
#
# miniLock only accepts secret phrases that are at least 32 characters long 
# and have at least 100 bits of entropy.
#
miniLockLib.secretPhraseIsAcceptable = (secretPhrase) ->
  secretPhrase.length >= 32 and zxcvbn(secretPhrase).entropy >= 100


# ---------------
# Email Addresses
# ---------------
#
# miniLock only accepts relatively standards compliant email addresses.
#
miniLockLib.emailAddressIsAcceptable = (emailAddress) ->
  EmailAddressPattern.test(emailAddress)

EmailAddressPattern = /[-0-9A-Z.+_]+@[-0-9A-Z.+_]+\\.[A-Z]{2,20}/i




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
# Call `miniLockLib.getKeyPair` to calculate a key pair from a secret phrase 
# and email address.
# Why are both inputs decoded?
# Why is the secret phrase hashed?
#
# Your `callback` receives a pair of `keys` like this:
#
#     miniLockLib.getKeyPair secretPhrase, emailAddress, (keys) ->
#        keys.publicKey is [32-bit Uint8Array]
#        keys.secretKey is [32-bit Uint8Array]
#
miniLockLib.getKeyPair = (secretPhrase, emailAddress, callback) ->
  # Sanitize both inputs against unexpected characters.
  secretPhrase = nacl.util.decodeUTF8(secretPhrase)
  emailAddress = nacl.util.decodeUTF8(emailAddress)
  
  # Create a 32-byte BLAKE2 hash digest of the secret phrase. WHY???
  hashDigestOfSecretPhrase = BLAKE2HashDigest(secretPhrase, length: 32)
  
  # Calculate keys for the secret phrase digest and email address salt.
  calculateCurve25519KeysFor hashDigestOfSecretPhrase, emailAddress, callback


# Calculate curve25519 key pair for the given `secret` and `salt`. When the 
# task is complete `callback` receives its `keys` like this:
#
#     calculateCurve25519KeysFor secret, salt, (keys) ->
#       keys.publicKey is [32-bit Uint8Array]
#       keys.secretKey is [32-bit Uint8Array]
#
calculateCurve25519KeysFor = (secret, salt, callback) ->
  # Define miniLock `scrypt` parameters for the calculation task:
  logN          = 17       # CPU/memory cost parameter (1 to 31).
  r             = 8        # Block size parameter. (I don’t know about this).
  dkLen         = 32       # Length of derived keys. (A miniLock key is 32 numbers).
  interruptStep = 1000     # Steps to split calculation with timeouts (default 1000).
  encoding      = 'base64' # Output encoding ('base64', 'hex', or null).
  
  # Decode and unpack the keys when the task is complete.
  whenKeysAreReady = (encodedBytes) ->
    decodedBytes = nacl.util.decodeBase64(encodedBytes)
    keys = nacl.box.keyPair.fromSecretKey(decodedBytes)
    callback(keys)
  
  # Send the task to `scrypt` for processing...
  scrypt(secret, salt, logN, r, dkLen, interruptStep, whenKeysAreReady, encoding)




# ------------
# miniLock IDs
# ------------
#
# miniLock IDs are meant to be easily communicable via email or instant messaging.
# A miniLock ID is a Base58 encoded string of a list of 33 numbers. 
# The first 32 numbers of your ID correspond to your curve25519 public key. 
# The last number is a checksum that was is derived by hashing your public key with BLAKE2 
# with a 1-byte output. 
# After constructing the 33 bytes of the miniLock ID, it is encoded 
# into a Base58 representation.
#
miniLockLib.makeID = (publicKey) ->
  if publicKey?.length is 32
    slots = new Uint8Array(33)
    slots[index] = publicKey[index] for index in [0..32]
    slots[32] = BLAKE2HashDigest(publicKey, length: 1)
    Base58.encode(slots)
  else
    if publicKey is undefined
      throw 'miniLockLib.makeID() received undefined public key.'
    if publicKey.length < 32
      throw 'miniLockLib.makeID() public key parameter was too short.'
    if publicKey.length > 32
      throw 'miniLockLib.makeID() public key parameter was too long.'




# -------
# Encrypt
# -------
#
#     miniLockLib.encrypt
#       file: buffer,
#       name: 'alice_and_bobby.txt'
#       miniLockIDs: [Alice.miniLockID, Bobby.miniLockID]
#       senderID: Alice.miniLockID
#       senderSecretKey: Alice.secretKey
#       callback: (error, encrypted) ->
#         error is undefined or it is a message String
#         encrypted.name is 'alice_and_bobby.txt.minilock'
#         encrypted.data.constructor is Blob
#         encrypted.data.size.constructor is Number
#         encrypted.senderID is Alice.miniLockID
#
miniLockLib.encrypt = (params) ->
  {file, name, miniLockIDs, senderID, senderSecretKey, callback} = params

  worker = new Worker(miniLockLib.pathToScripts+'/miniLockCryptoWorker.js')
  
  worker.onmessage = (message) ->
    if message.error?
      worker.terminate()
      callback WorkerErrorMessages[message.error]
    else if message.data.blob?
      worker.terminate()
      callback undefined, {
        name: message.data.saveName
        data: new Blob([message.data.blob])
        type: 'application/minilock'
        senderID: message.data.senderID
      }
  
  worker.postMessage({
    operation: 'encrypt'
    data: new Uint8Array(file.data)
    name: file.name
    saveName: name + '.minilock'
    fileKey: nacl.randomBytes(32)
    fileNonce: nacl.randomBytes(24).subarray(0, 16)
    decryptInfoNonces: (nacl.randomBytes(24) for i in [0..miniLockIDs.length])
    ephemeral: nacl.box.keyPair()
    miniLockIDs: miniLockIDs
    myMiniLockID: senderID
    mySecretKey: senderSecretKey
  })




# -------
# Decrypt
# -------
#
#     miniLockLib.decrypt
#       file: buffer,
#       name: 'alice_and_bobby.txt.minilock'
#       myMiniLockID: Alice.miniLockID
#       mySecretKey: Alice.secretKey
#       callback: (error, decrypted) ->
#         error is undefined or it is a message String
#         encrypted.name is 'alice_and_bobby.txt'
#         encrypted.data.constructor is Blob
#         encrypted.data.size.constructor is Number
#         encrypted.senderID is Alice.miniLockID
#
miniLockLib.decrypt = (params) ->
  {file, myMiniLockID, mySecretKey, callback} = params

  worker = new Worker(miniLockLib.pathToScripts+'/miniLockCryptoWorker.js')
  
  worker.onmessage = (message) ->
    if message.error?
      worker.terminate()
      callback WorkerErrorMessages[message.error]
    else if message.data.blob?
      worker.terminate()
      callback undefined, {
        name: message.data.name,
        data: new Blob([message.data.blob])
        type: ''
        senderID: message.data.senderID
      }
  
  worker.postMessage({
    operation: 'decrypt'
    data: new Uint8Array(file.data)
    myMiniLockID: myMiniLockID
    mySecretKey: mySecretKey
  })




WorkerErrorMessages =
  1: 'miniLock could not encrypt this file.'
  2: 'miniLock could not decrypt this file.'
  3: 'miniLock could not decrypt this file — it might be corrupt.'
  4: 'This file seems to be encrypted for another version of miniLock.'
  5: 'miniLock could not determine the sender of this file.'
  6: 'This file does not seem to be encrypted for your miniLock ID. Check that you are logged in with the correct miniLock ID.'
  7: 'The integrity of this file could not be verified.'


# Returns a BLAKE2 hash digest of `input`. Specify the digest `length` as a `Number`.
BLAKE2HashDigest = (input, options={}) ->
  hash = new BLAKE2s(options.length)
  hash.update(input)
  hash.digest()

