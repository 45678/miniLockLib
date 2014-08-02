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
  encoding      = 'base64' # Output encoding ('base64', 'hex', or null).
  
  # Send the task to `scrypt` for processing...
  scrypt(secret, salt, logN, r, dkLen, interruptStep, whenKeysAreReady, encoding)




# ------------
# miniLock IDs
# ------------
#
# miniLock IDs are meant to be easily communicable via email or instant messaging.
# A miniLock ID is a Base58 encoded string of a list of 33 numbers. 
# The first 32 numbers of your ID correspond to your curve25519 public key. 
# The last number is a checksum that was is derived by hashing your public key 
# with BLAKE2  with a 1-byte output. After constructing the 33 bytes of the 
# miniLock ID, it is encoded into a Base58 representation.
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
#       keys: {publicKey: Uint8Array, secretKey: Uint8Array}
#       miniLockIDs: [Alice.miniLockID, Bobby.miniLockID]
#       callback: (error, encrypted) ->
#         error is undefined or it is a message String
#         encrypted.name is 'alice_and_bobby.txt.minilock'
#         encrypted.data.constructor is Blob
#         encrypted.data.size.constructor is Number
#         encrypted.senderID is Alice.miniLockID
#
miniLockLib.encrypt = (params) ->
  {file, name, miniLockIDs, keys, callback} = params

  worker = new CryptoWorker
  
  worker.onmessage = (message) ->
    if message.data.error?
      worker.terminate()
      callback CryptoWorker.ErrorMessages[message.data.error]
    else if message.data.blob?
      worker.terminate()
      callback undefined, {
        name: message.data.saveName
        data: new Blob [message.data.blob], type: 'application/minilock'
        senderID: message.data.senderID
      }
  
  worker.postMessage
    operation: 'encrypt'
    data: new Uint8Array(file.data)
    name: file.name
    saveName: name+'.minilock'
    fileKey: nacl.randomBytes(32)
    fileNonce: nacl.randomBytes(24).subarray(0, 16)
    decryptInfoNonces: (nacl.randomBytes(24) for i in [0..miniLockIDs.length])
    ephemeral: nacl.box.keyPair()
    miniLockIDs: miniLockIDs
    myMiniLockID: miniLockLib.makeID(keys.publicKey)
    mySecretKey: keys.secretKey




# -------
# Decrypt
# -------
#
#     miniLockLib.decrypt
#       file: buffer,
#       keys: {publicKey: Uint8Array, secretKey: Uint8Array}
#       callback: (error, decrypted) ->
#         error is undefined or it is a message String
#         decrypted.name is 'alice_and_bobby.txt'
#         decrypted.data.constructor is Blob
#         decrypted.data.size.constructor is Number
#         decrypted.senderID is Alice.miniLockID
#
miniLockLib.decrypt = (params) ->
  {file, keys, callback} = params

  worker = new CryptoWorker
  
  worker.onmessage = (message) ->
    if message.data.error?
      worker.terminate()
      callback CryptoWorker.ErrorMessages[message.data.error]
    else if message.data.blob?
      worker.terminate()
      callback undefined, {
        name: message.data.name,
        data: new Blob([message.data.blob])
        senderID: message.data.senderID
      }
  
  worker.postMessage
    operation: 'decrypt'
    data: new Uint8Array(file.data)
    myMiniLockID: miniLockLib.makeID(keys.publicKey)
    mySecretKey: keys.secretKey




# Construct a new worker to perform an encrypt or decrypt operation.
CryptoWorker = ->
  new Worker(miniLockLib.pathToScripts+'/miniLockCryptoWorker.js')

# Explanations of miniLock’s numeric error codes.
CryptoWorker.ErrorMessages =
  # Encryption errors
  1: 'General encryption error'
  # Decryption errors
  2: 'General decryption error'
  3: 'Could not parse header'
  4: 'Invalid header version'
  5: 'Could not validate sender ID'
  6: 'File is not encrypted for this recipient'
  7: 'Could not validate ciphertext hash'


# Construct a BLAKE2 hash digest of `input`. Specify digest `length` as a `Number`.
BLAKE2HashDigest = (input, options={}) ->
  hash = new BLAKE2s(options.length)
  hash.update(input)
  hash.digest()

