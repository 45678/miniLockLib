AbstractOperation = require("./AbstractOperation")
NACL = require("./NACL")
{encodeUTF8, decodeBase64} = NACL.util
{byteArrayToNumber} = require("./util")

class DecryptOperation extends AbstractOperation
  module.exports = this

  constructor: (params={}) ->
    {@data, @keys, @callback} = params
    @decryptedBytes = []
    @start() if params.start?

  start: (callback) =>
    @callback = callback if callback?
    if @data is undefined
      throw "Can’t start miniLockLib.#{@constructor.name} without data."
    if @keys?.secretKey is undefined
      throw "Can’t start miniLockLib.#{@constructor.name} without keys."
    if typeof @callback isnt "function"
      throw "Can’t start miniLockLib.#{@constructor.name} without a callback."
    @startedAt = Date.now()
    @run()

  run: ->
    @decryptName (error, nameWasDecrypted, startPositionOfDataBytes) =>
      if nameWasDecrypted?
        @decryptData startPositionOfDataBytes, (error, blob) =>
          @end(error, blob)
      else
        @end(error)

  end: (error, blob) ->
    @streamDecryptor.clean() if @streamDecryptor?
    AbstractOperation::end.call(this, error, blob)

  oncomplete: (blob) ->
    @callback(undefined, {
      data: blob
      name: @name
      senderID: @permit.senderID
      recipientID: @permit.recipientID
      duration: @duration
      startedAt: @startedAt
      endedAt: @endedAt
    })

  onerror: (error) ->
    @callback(error)

  decryptName: (callback) ->
    @constructStreamDecryptor (error, lengthOfHeader) =>
      if error then return callback(error)
      startPosition = 12+lengthOfHeader
      endPosition   = 12+lengthOfHeader+256+4+16
      @readSliceOfData startPosition, endPosition, (error, sliceOfBytes) =>
        if error then return callback(error)
        fixedLengthNameAsBytes = @streamDecryptor.decryptChunk(sliceOfBytes, no)
        if fixedLengthNameAsBytes
          nameAsBytes = (byte for byte in fixedLengthNameAsBytes when byte isnt 0)
          @name = encodeUTF8(nameAsBytes)
          callback(undefined, @name?, endPosition)
        else
          callback("DecryptOperation failed to decrypt file name.")

  decryptData: (position, callback) ->
    @constructStreamDecryptor (error, lengthOfHeader) =>
      if error then return callback(error)
      startPosition = position
      endPosition   = position+@chunkSize+4+16
      @readSliceOfData startPosition, endPosition, (error, sliceOfBytes) =>
        isLast = position+sliceOfBytes.length is @data.size
        decryptedBytes = @streamDecryptor.decryptChunk(sliceOfBytes, isLast)
        if decryptedBytes
          @decryptedBytes.push(decryptedBytes)
          if isLast
            callback(undefined, new Blob @decryptedBytes)
          else
            @decryptData(endPosition, callback)
        else
          callback("DecryptOperation failed to decrypt file data.")

  constructStreamDecryptor: (callback) ->
    @decryptUniqueNonceAndPermit (error, uniqueNonce, permit, lengthOfHeader) =>
      if uniqueNonce and permit and lengthOfHeader
        @uniqueNonce = uniqueNonce
        @permit = permit
        @fileKey = permit.fileInfo.fileKey
        @fileNonce = permit.fileInfo.fileNonce
        @streamDecryptor = NACL.stream.createDecryptor(@fileKey, @fileNonce, @chunkSize)
        @constructStreamDecryptor = (callback) -> callback(undefined, lengthOfHeader)
        @constructStreamDecryptor(callback)
      else
        callback(error)

  decryptUniqueNonceAndPermit: (callback) ->
    @readHeader (error, header, lengthOfHeader) =>
      if error
        callback(error)
      else
        returned = @findUniqueNonceAndPermit(header)
        if returned
          [uniqueNonce, permit] = returned
          callback(undefined, uniqueNonce, permit, lengthOfHeader)
        else
          callback("File is not encrypted for this recipient")

  findUniqueNonceAndPermit: (header) ->
    ephemeral = decodeBase64(header.ephemeral)
    for encodedUniqueNonce, encodedEncryptedPermit of header.decryptInfo
      uniqueNonce = decodeBase64(encodedUniqueNonce)
      decodedEncryptedPermit = decodeBase64(encodedEncryptedPermit)
      permit = @decryptPermit(decodedEncryptedPermit, uniqueNonce, ephemeral)
      if permit then return [uniqueNonce, permit]
    return undefined

  decryptPermit: (decodedEncryptedPermit, uniqueNonce, ephemeral) ->
    decryptedPermitAsBytes = NACL.box.open(decodedEncryptedPermit, uniqueNonce, ephemeral, @keys.secretKey)
    if decryptedPermitAsBytes
      decryptedPermitAsString = encodeUTF8(decryptedPermitAsBytes)
      decryptedPermit = JSON.parse(decryptedPermitAsString)
      decodedEncryptedFileInfo = decodeBase64(decryptedPermit.fileInfo)
      senderPublicKey = miniLockLib.ID.decode(decryptedPermit.senderID)
      decryptedPermit.fileInfo = @decryptFileInfo(decodedEncryptedFileInfo, uniqueNonce, senderPublicKey)
      return decryptedPermit
    else
      return undefined

  decryptFileInfo: (decodedEncryptedFileInfo, uniqueNonce, senderPublicKey) ->
    decryptedFileInfoAsBytes = NACL.box.open(decodedEncryptedFileInfo, uniqueNonce, senderPublicKey, @keys.secretKey)
    if (decryptedFileInfoAsBytes)
      decryptedFileInfoAsString = encodeUTF8(decryptedFileInfoAsBytes)
      decryptedFileInfo = JSON.parse(decryptedFileInfoAsString)
      return {
        fileHash:  decryptedFileInfo.fileHash
        fileKey:   decodeBase64(decryptedFileInfo.fileKey)
        fileNonce: decodeBase64(decryptedFileInfo.fileNonce)
      }
      return decryptedFileInfo
    else
      return undefined

  readHeader: (callback) ->
    @readLengthOfHeader (error, lengthOfHeader) =>
      if error then return callback(error)
      @readSliceOfData 12, lengthOfHeader+12, (error, sliceOfBytes) =>
        if error then return callback(error)
        headerAsString = encodeUTF8(sliceOfBytes)
        header = JSON.parse(headerAsString)
        callback(undefined, header, lengthOfHeader)

  readLengthOfHeader: (callback) ->
    @readSliceOfData 8, 12, (error, sliceOfBytes) =>
      if error then return callback(error)
      lengthOfHeader = byteArrayToNumber(sliceOfBytes)
      callback(undefined, lengthOfHeader)
