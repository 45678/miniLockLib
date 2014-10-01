module.exports = class DecryptOperation
  NaCl = require "./NaCl"
  {encodeUTF8, decodeBase64} = NaCl.util
  {byteArrayToNumber} = require "./util"

  chunkSize: 1024 * 1024
  readSliceOfData: require "./readSliceOfData"

  constructor: (params={}) ->
    {@data, @keys, @callback} = params
    @decryptedBytes = []
    @start() if params.start?

  start: (callback) =>
    @callback = callback if callback?
    if @callback?.constructor isnt Function
      throw "Can’t start decrypt operation without a callback function."
    switch
      when @data is undefined
        @callback "Can’t decrypt without a Blob of data."
      when @keys?.secretKey is undefined
        @callback "Can’t decrypt without a set of keys."
      else
        @startedAt = Date.now()
        @run()
    return this

  run: ->
    @readHeader (error, header, sizeOfHeader) =>
      @["decryptVersion#{header.version}Attributes"] (error, attributes, startOfEncryptedDataBytes) =>
        if error is undefined
          @decryptData startOfEncryptedDataBytes, (error, blob) =>
            @end(error, blob, attributes, header, sizeOfHeader)
        else
          @end(error, undefined, attributes, header, sizeOfHeader)

  end: (error, blob, attributes, header, sizeOfHeader) ->
    @streamDecryptor.clean() if @streamDecryptor?
    @endedAt = Date.now()
    @duration = @endedAt - @startedAt
    if error
      @onerror(error, header, sizeOfHeader)
    else
      @oncomplete(blob, attributes, header, sizeOfHeader)

  oncomplete: (blob, attributes, header, sizeOfHeader) ->
    @callback(undefined, {
      data: blob
      name: attributes.name
      type: attributes.type
      time: attributes.time
      senderID: @permit.senderID
      recipientID: @permit.recipientID
      fileKey: @permit.fileInfo.fileKey
      fileNonce: @permit.fileInfo.fileNonce
      fileHash: @permit.fileInfo.fileHash
      duration: @duration
      startedAt: @startedAt
      endedAt: @endedAt
    }, header, sizeOfHeader)

  onerror: (error, header, sizeOfHeader) ->
    @callback(error, undefined, header, sizeOfHeader)

  decryptVersion1Attributes: (callback) ->
    @constructMap (error, map) =>
      if error then return callback(error)
      @constructStreamDecryptor (error) =>
        if error then return callback(error)
        {ciphertextBytes} = map
        start = ciphertextBytes.start
        end   = ciphertextBytes.start+256+4+16
        @readSliceOfData start, end, (error, sliceOfBytes) =>
          if error then return callback(error)
          if decryptedBytes = @streamDecryptor.decryptChunk(sliceOfBytes, no)
            nameAsBytes = (byte for byte in decryptedBytes when byte isnt 0)
            attributes =
              name: encodeUTF8(nameAsBytes)
            callback undefined, attributes, end
          else
            callback "Failed to decrypt version 1 file attributes."

  decryptVersion2Attributes: (callback) ->
    @constructMap (error, map) =>
      if error then return callback(error)
      @constructStreamDecryptor (error) =>
        if error then return callback(error)
        {ciphertextBytes} = map
        start = ciphertextBytes.start
        end   = ciphertextBytes.start+256+128+24+4+16
        @readSliceOfData start, end, (error, sliceOfBytes) =>
          if error then return callback(error)
          if decryptedBytes = @streamDecryptor.decryptChunk(sliceOfBytes, no)
            decryptedNameBytes = decryptedBytes.subarray(0, 256)
            nameAsBytes = (byte for byte in decryptedNameBytes when byte isnt 0)
            decryptedTypeBytes = decryptedBytes.subarray(256, 256+128)
            typeAsBytes = (byte for byte in decryptedTypeBytes when byte isnt 0)
            decryptedTimeBytes = decryptedBytes.subarray(256+128, 256+128+24)
            timeAsBytes = (byte for byte in decryptedTimeBytes when byte isnt 0)
            attributes =
              name: encodeUTF8(nameAsBytes)
              type: encodeUTF8(typeAsBytes)
              time: encodeUTF8(timeAsBytes)
            callback undefined, attributes, end
          else
            callback "Failed to decrypt version 2 file attributes."

  decryptData: (position, callback) ->
    @constructStreamDecryptor (error) =>
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
          callback "Failed to decrypt slice of data at [#{startPosition}..#{endPosition}]"

  constructMap: (callback) ->
    @readHeader (error, header, sizeOfHeader) =>
      if (error is undefined) and sizeOfHeader?
        magicBytes        = {start: 0, end: 8}
        sizeOfHeaderBytes = {start: 8, end: 12}
        headerBytes       = {start: 12, end: 12+sizeOfHeader}
        ciphertextBytes   = {start: headerBytes.end, end: @data.size}
      callback error, {magicBytes, sizeOfHeaderBytes, headerBytes, ciphertextBytes}

  constructStreamDecryptor: (callback) ->
    @decryptUniqueNonceAndPermit (error, uniqueNonce, permit) =>
      if uniqueNonce and permit
        @uniqueNonce = uniqueNonce
        @permit = permit
        @fileKey = permit.fileInfo.fileKey
        @fileNonce = permit.fileInfo.fileNonce
        @streamDecryptor = NaCl.stream.createDecryptor(@fileKey, @fileNonce, @chunkSize)
        @constructStreamDecryptor = (callback) -> callback(undefined)
        @constructStreamDecryptor(callback)
      else
        callback(error)

  decryptUniqueNonceAndPermit: (callback) ->
    @readHeader (error, header) =>
      if error
        callback(error)
      else
        returned = @findUniqueNonceAndPermit(header)
        if returned
          [uniqueNonce, permit] = returned
          callback undefined, uniqueNonce, permit
        else
          callback "Can’t decrypt this file with this set of keys."

  findUniqueNonceAndPermit: (header) ->
    ephemeral = decodeBase64(header.ephemeral)
    for encodedUniqueNonce, encodedEncryptedPermit of header.decryptInfo
      uniqueNonce = decodeBase64(encodedUniqueNonce)
      decodedEncryptedPermit = decodeBase64(encodedEncryptedPermit)
      permit = @decryptPermit(decodedEncryptedPermit, uniqueNonce, ephemeral)
      if permit then return [uniqueNonce, permit]
    return undefined

  decryptPermit: (decodedEncryptedPermit, uniqueNonce, ephemeral) ->
    decryptedPermitAsBytes = NaCl.box.open(decodedEncryptedPermit, uniqueNonce, ephemeral, @keys.secretKey)
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
    decryptedFileInfoAsBytes = NaCl.box.open(decodedEncryptedFileInfo, uniqueNonce, senderPublicKey, @keys.secretKey)
    if (decryptedFileInfoAsBytes)
      decryptedFileInfoAsString = encodeUTF8(decryptedFileInfoAsBytes)
      decryptedFileInfo = JSON.parse(decryptedFileInfoAsString)
      return {
        fileHash:  decodeBase64(decryptedFileInfo.fileHash)
        fileKey:   decodeBase64(decryptedFileInfo.fileKey)
        fileNonce: decodeBase64(decryptedFileInfo.fileNonce)
      }
    else
      return undefined

  readHeader: (callback) ->
    @readSizeOfHeader (error, sizeOfHeader) =>
      if error then return callback(error)
      @readSliceOfData 12, 12+sizeOfHeader, (error, sliceOfBytes) =>
        if error then return callback(error)
        headerAsString = encodeUTF8(sliceOfBytes)
        header = JSON.parse(headerAsString)
        callback(undefined, header, sizeOfHeader)

  readSizeOfHeader: (callback) ->
    @readSliceOfData 8, 12, (error, sliceOfBytes) =>
      if error then return callback(error)
      sizeOfHeader = byteArrayToNumber(sliceOfBytes)
      callback(error, sizeOfHeader)
