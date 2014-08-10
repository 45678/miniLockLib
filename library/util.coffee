# Convert a Number to a 4-byte little-endian Uint8Array
exports.numberToByteArray = (n) ->
  byteArray = new Uint8Array(4)
  for index in [0..4]
    byteArray[index] = n & 255
    n = n >> 8
  byteArray

# Convert a 4-byte little-endian Uint8Array to a Number
exports.byteArrayToNumber = (byteArray) ->
  n = 0
  for index in [3..0]
    n += byteArray[index]
    if (index isnt 0)
      n = n << 8
  return n
