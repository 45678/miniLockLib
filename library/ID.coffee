Base58 = require "./Base58"
BLAKE2s = require "./BLAKE2s"

# Encode a public key as a miniLock ID.
#
# Accepts a <code>Uint8Array</code> <code>publicKey</code> and returns a
# miniLock ID <code>String</code> if the input is acceptable.
exports.encode = (publicKey) ->
  if publicKey?.length is 32
    slots = new Uint8Array(33)
    slots[index] = publicKey[index] for index in [0..32]
    slots[32] = (new BLAKE2s length: 1).update(publicKey).digest()[0]
    Base58.encode(slots)
  else
    undefined

# Decode the public key from a <code>miniLockID</code>.
#
# Accepts a miniLock ID <code>String</code> and returns a <code>Uint8Array</code>
# <code>publicKey</code> if the input is acceptable.
exports.decode = (miniLockID) ->
  slots = Base58.decode(miniLockID)
  if slots.length is 33
    publicKey = new Uint8Array(slots.subarray(0, 32))
    encodedChecksum = slots[32]
    trueChecksum = (new BLAKE2s length: 1).update(publicKey).digest()[0]
    return publicKey if encodedChecksum is trueChecksum
  undefined

# `true` if the `miniLockID` is acceptable and `false` if it is not.
exports.isAcceptable = (miniLockID) ->
  /^[1-9A-Za-z]{40,55}$/.test(miniLockID) and @decode(miniLockID)?
