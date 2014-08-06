class miniLockLib.DecryptOperation extends miniLockLib.BasicOperation
  constructor: (params={}) ->
    {@data, @keys, @callback} = params
    @decryptedBytes = []
    super(params)

  run: ->
    @decryptName (error, nameWasDecrypted, startPositionOfDataBytes) =>
      if nameWasDecrypted?
        @decryptData(startPositionOfDataBytes, @end)
      else
        @end(error)

  end: (error, blob) =>
    @streamDecryptor.clean() if @streamDecryptor?
    super(error, blob)
  
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
          @name = nacl.util.encodeUTF8(nameAsBytes)
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
        @streamDecryptor = nacl.stream.createDecryptor(@fileKey, @fileNonce, @chunkSize)
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
    ephemeral = nacl.util.decodeBase64(header.ephemeral)
    for encodedUniqueNonce, encodedEncryptedPermit of header.decryptInfo
      uniqueNonce = nacl.util.decodeBase64(encodedUniqueNonce)
      decodedEncryptedPermit = nacl.util.decodeBase64(encodedEncryptedPermit)
      permit = @decryptPermit(decodedEncryptedPermit, uniqueNonce, ephemeral)
      if permit then return [uniqueNonce, permit]
    return undefined
  
  decryptPermit: (decodedEncryptedPermit, uniqueNonce, ephemeral) ->
    decryptedPermitAsBytes = nacl.box.open(decodedEncryptedPermit, uniqueNonce, ephemeral, @keys.secretKey)
    if decryptedPermitAsBytes
      decryptedPermitAsString = nacl.util.encodeUTF8(decryptedPermitAsBytes)
      decryptedPermit = JSON.parse(decryptedPermitAsString)
      decodedEncryptedFileInfo = nacl.util.decodeBase64(decryptedPermit.fileInfo)
      senderPublicKey = miniLockLib.ID.decode(decryptedPermit.senderID)
      decryptedPermit.fileInfo = @decryptFileInfo(decodedEncryptedFileInfo, uniqueNonce, senderPublicKey)
      return decryptedPermit
    else
      return undefined
  
  decryptFileInfo: (decodedEncryptedFileInfo, uniqueNonce, senderPublicKey) ->
    decryptedFileInfoAsBytes = nacl.box.open(decodedEncryptedFileInfo, uniqueNonce, senderPublicKey, @keys.secretKey)
    if (decryptedFileInfoAsBytes)
      decryptedFileInfoAsString = nacl.util.encodeUTF8(decryptedFileInfoAsBytes)
      decryptedFileInfo = JSON.parse(decryptedFileInfoAsString)
      return {
        fileHash:  decryptedFileInfo.fileHash
        fileKey:   nacl.util.decodeBase64(decryptedFileInfo.fileKey)
        fileNonce: nacl.util.decodeBase64(decryptedFileInfo.fileNonce)
      }
      return decryptedFileInfo
    else
      return undefined
  
  readHeader: (callback) ->
    @readLengthOfHeader (error, lengthOfHeader) =>
      if error then return callback(error)
      @readSliceOfData 12, lengthOfHeader+12, (error, sliceOfBytes) =>
        if error then return callback(error)
        headerAsString = nacl.util.encodeUTF8(sliceOfBytes)
        header = JSON.parse(headerAsString)
        callback(undefined, header, lengthOfHeader)
  
  readLengthOfHeader: (callback) ->
    @readSliceOfData 8, 12, (error, sliceOfBytes) ->
      if error then return callback(error)
      lengthOfHeader = miniLockLib.byteArrayToNumber(sliceOfBytes)
      callback(undefined, lengthOfHeader)

