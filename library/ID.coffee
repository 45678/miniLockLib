# ------------
# miniLock IDs
# ------------

Base58 = require("./Base58")
BLAKE2 = require("./BLAKE2s")

ID = module.exports = {}

# Returns `true` if `id` is acceptable and `false` if it is not.
ID.isAcceptable = (id) ->
  /^[1-9A-Za-z]{40,55}$/.test(id) and miniLockLib.ID.decode(id)?




# Encode a 32-bit public key as a miniLockID.
ID.encode = (publicKey) ->
  if publicKey?.length is 32
    slots = new Uint8Array(33)
    slots[index] = publicKey[index] for index in [0..32]
    slots[32] = BLAKE2HashDigest(publicKey, length: 1)[0]
    Base58.encode(slots)
  else
    undefined




# Decode a 32-bit public key from a miniLockID.
ID.decode = (id) ->
  slots = Base58.decode(id)
  if slots.length is 33
    publicKey = new Uint8Array(slots.subarray(0, 32))
    encodedChecksum = slots[32]
    trueChecksum = BLAKE2HashDigest(publicKey, length: 1)[0]
    return publicKey if encodedChecksum is trueChecksum
  undefined




# Construct a BLAKE2 hash digest of `input`. Specify digest `length` as a `Number`.
BLAKE2HashDigest = (input, options={}) ->
  hash = new BLAKE2(options.length)
  hash.update(input)
  hash.digest()
