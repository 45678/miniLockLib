class miniLockLib.EncryptOperation extends miniLockLib.BasicOperation
  constructor: (params={})->
    {@data, @name, @miniLockIDs, @callback} = params
    @author = {keys: params.keys}
    @ephemeral = nacl.box.keyPair()
    @fileKey = nacl.randomBytes(32)
    @fileNonce = nacl.randomBytes(24).subarray(0, 16)
    @hash = new BLAKE2s(32)
    @ciphertextBytes = []
    super(params)

  run: ->
    @encryptName()
    @encryptData 0, (error, dataWasEncrypted) =>
      if dataWasEncrypted?
        @constructHeader()
        fileFormat = [
          "miniLock"
          @lengthOfHeaderIn4Bytes
          @headerJSONBytes
          @ciphertextBytes...
        ]
        @end(error, new Blob fileFormat, type: "application/minilock")
      else
        @end(error)

  end: (error, blob) ->
    @streamEncryptor.clean() if @streamEncryptor?
    super(error, blob)

  oncomplete: (blob) ->
    @callback(undefined, {
      data: blob
      name: @name + ".minilock"
      senderID: miniLockLib.ID.encode(@author.keys.publicKey)
      duration: @duration
      startedAt: @startedAt
      endedAt: @endedAt
    })

  onerror: (error) ->
    @callback(error)

  encryptName: ->
    @constructStreamEncryptor()
    if encryptedBytes = @streamEncryptor.encryptChunk(@fixedLengthDecodedName(), no)
      @hash.update(encryptedBytes)
      @ciphertextBytes.push(encryptedBytes)
    else
      throw "EncryptOperation failed to encrypt file name."

  encryptData: (position, callback) ->
    @constructStreamEncryptor()
    @readSliceOfData position, position+@chunkSize, (error, sliceOfBytes) =>
      if error then return callback(error)
      isLastSlice = position+sliceOfBytes.length is @data.size
      if encryptedBytes = @streamEncryptor.encryptChunk(sliceOfBytes, isLastSlice)
        @hash.update(encryptedBytes)
        @ciphertextBytes.push(encryptedBytes)
        if isLastSlice
          @hash.digest()
          callback(undefined, @hash.isFinished)
        else
          @encryptData(position+@chunkSize, callback)
      else
        callback "EncryptOperation failed to encrypt file data."

  constructHeader: ->
    @header =
      version: 1
      ephemeral: nacl.util.encodeBase64(@ephemeral.publicKey)
      decryptInfo: @encodedEncryptedPermits()
    headerJSON = JSON.stringify(@header)
    @lengthOfHeaderIn4Bytes = miniLockLib.numberToByteArray(headerJSON.length)
    @headerJSONBytes = nacl.util.decodeUTF8(headerJSON)
    return @header
    
  constructStreamEncryptor: ->
    @streamEncryptor ?= nacl.stream.createEncryptor(@fileKey, @fileNonce, @chunkSize)
  
  fixedLengthDecodedName: ->
    fixedLength = new Uint8Array(256)
    decodedName = nacl.util.decodeUTF8(@name)
    if decodedName.length > fixedLength.length
      throw "EncryptOperation file name is too long. 256-characters max please."
    fixedLength.set(decodedName)
    return fixedLength

  encodedEncryptedPermits: ->
    permits = {}
    for miniLockID in @miniLockIDs
      [uniqueNonce, encryptedPermit] = @encryptedPermit(miniLockID)
      encodedUniqueNonce = nacl.util.encodeBase64(uniqueNonce)
      encodedEncryptedPermit = nacl.util.encodeBase64(encryptedPermit)
      permits[encodedUniqueNonce] = encodedEncryptedPermit
    return permits

  encryptedPermit: (miniLockID) ->
    [uniqueNonce, permit] = @permit(miniLockID)
    decodedPermitJSON = nacl.util.decodeUTF8(JSON.stringify(permit))
    recipientPublicKey = Base58.decode(miniLockID).subarray(0, 32)
    encryptedPermit = nacl.box(decodedPermitJSON, uniqueNonce, recipientPublicKey, @ephemeral.secretKey)
    [uniqueNonce, encryptedPermit]

  permit: (miniLockID) ->
    uniqueNonce = nacl.randomBytes(24)
    [uniqueNonce, {
      senderID: miniLockLib.ID.encode(@author.keys.publicKey)
      recipientID: miniLockID
      fileInfo: nacl.util.encodeBase64(@encryptedFileInfo(miniLockID, uniqueNonce))
    }]
  
  encryptedFileInfo: (miniLockID, uniqueNonce) ->
    decodedFileInfoJSON = nacl.util.decodeUTF8(JSON.stringify(@permitFileInfo()))
    recipientPublicKey = Base58.decode(miniLockID).subarray(0, 32)
    nacl.box(decodedFileInfoJSON, uniqueNonce, recipientPublicKey, @author.keys.secretKey)

  permitFileInfo: ->
    fileKey:   nacl.util.encodeBase64(@fileKey)
    fileNonce: nacl.util.encodeBase64(@fileNonce)
    fileHash:  nacl.util.encodeBase64(@hash.digest())
