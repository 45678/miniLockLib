# Base58 encoding/decoding
# Originally written by Mike Hearn for BitcoinJ
# Copyright (c) 2011 Google Inc
# Ported to JavaScript by Stefan Thomas
# Merged Uint8Array refactorings from base58-native by Stephen Pair
# Copyright (c) 2013 BitPay Inc
Base58 = module.exports = {}
Base58.ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
Base58.ALPHABET_MAP = {}
i = 0

while i < Base58.ALPHABET.length
  Base58.ALPHABET_MAP[Base58.ALPHABET.charAt(i)] = i
  i++
Base58.BASE = 58
Base58.encode = (buffer) ->
  return ""  if buffer.length is 0
  i = undefined
  j = undefined
  digits = [0]
  i = 0
  while i < buffer.length
    j = 0
    while j < digits.length
      digits[j] <<= 8
      j++
    digits[0] += buffer[i]
    carry = 0
    j = 0
    while j < digits.length
      digits[j] += carry
      carry = (digits[j] / Base58.BASE) | 0
      digits[j] %= Base58.BASE
      ++j
    while carry
      digits.push carry % Base58.BASE
      carry = (carry / Base58.BASE) | 0
    i++

  # deal with leading zeros
  i = 0
  while i < buffer.length - 1 and buffer[i] is 0
    digits.push 0
    i++
  digits.reverse().map((digit) ->
    Base58.ALPHABET[digit]
  ).join ""

Base58.decode = (string) ->
  return new Uint8Array(0)  if string.length is 0
  input = string.split("").map((c) ->
    throw "Non-base58 character"  if Base58.ALPHABET.indexOf(c) is -1
    Base58.ALPHABET_MAP[c]
  )
  i = undefined
  j = undefined
  bytes = [0]
  i = 0
  while i < input.length
    j = 0
    while j < bytes.length
      bytes[j] *= Base58.BASE
      j++
    bytes[0] += input[i]
    carry = 0
    j = 0
    while j < bytes.length
      bytes[j] += carry
      carry = bytes[j] >> 8
      bytes[j] &= 0xff
      ++j
    while carry
      bytes.push carry & 0xff
      carry >>= 8
    i++

  # deal with leading zeros
  i = 0
  while i < input.length - 1 and input[i] is 0
    bytes.push 0
    i++
  new Uint8Array(bytes.reverse())
