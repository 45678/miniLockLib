BasicOperation = require("./BasicOperation")
NACL = require("./NACL")
BLAKE2s = require("./BLAKE2s")

class EncryptOperation extends BasicOperation
  module.exports = this
  
  constructor: (params={})->
    {@data, @keys, @name, @miniLockIDs, @callback} = params
    @ephemeral = NACL.box.keyPair()
    @fileKey = NACL.randomBytes(32)
    @fileNonce = NACL.randomBytes(24).subarray(0, 16)
    @hash = new BLAKE2s(32)
    @ciphertextBytes = []
    @start() if params.start?

  start: (callback) =>
    @callback = callback if callback?
    if (@keys?.publicKey is undefined) or (@keys?.secretKey is undefined)
      throw "Can’t start miniLockLib.#{@constructor.name} without keys."
    if @miniLockIDs is undefined
      throw "Can’t start miniLockLib.#{@constructor.name} without miniLockIDs."
    if @data?.constructor isnt Blob
      throw "Can’t start miniLockLib.#{@constructor.name} without data."
    if typeof @callback isnt "function"
      throw "Can’t start miniLockLib.#{@constructor.name} without a callback."
    @startedAt = Date.now()
    @run()

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

  end: (error, blob) =>
    @streamEncryptor.clean() if @streamEncryptor?
    BasicOperation::end.call(this, error, blob)

  oncomplete: (blob) ->
    @callback(undefined, {
      data: blob
      name: @name + ".minilock"
      senderID: miniLockLib.ID.encode(@keys.publicKey)
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
      ephemeral: NACL.util.encodeBase64(@ephemeral.publicKey)
      decryptInfo: @encodedEncryptedPermits()
    headerJSON = JSON.stringify(@header)
    @lengthOfHeaderIn4Bytes = miniLockLib.numberToByteArray(headerJSON.length)
    @headerJSONBytes = NACL.util.decodeUTF8(headerJSON)
    return @header
    
  constructStreamEncryptor: ->
    @streamEncryptor ?= NACL.stream.createEncryptor(@fileKey, @fileNonce, @chunkSize)
  
  fixedLengthDecodedName: ->
    fixedLength = new Uint8Array(256)
    decodedName = NACL.util.decodeUTF8(@name)
    if decodedName.length > fixedLength.length
      throw "EncryptOperation file name is too long. 256-characters max please."
    fixedLength.set(decodedName)
    return fixedLength

  encodedEncryptedPermits: ->
    permits = {}
    for miniLockID in @miniLockIDs
      [uniqueNonce, encryptedPermit] = @encryptedPermit(miniLockID)
      encodedUniqueNonce = NACL.util.encodeBase64(uniqueNonce)
      encodedEncryptedPermit = NACL.util.encodeBase64(encryptedPermit)
      permits[encodedUniqueNonce] = encodedEncryptedPermit
    return permits

  encryptedPermit: (miniLockID) ->
    [uniqueNonce, permit] = @permit(miniLockID)
    decodedPermitJSON = NACL.util.decodeUTF8(JSON.stringify(permit))
    recipientPublicKey = miniLockLib.ID.decode(miniLockID)
    encryptedPermit = NACL.box(decodedPermitJSON, uniqueNonce, recipientPublicKey, @ephemeral.secretKey)
    [uniqueNonce, encryptedPermit]

  permit: (miniLockID) ->
    uniqueNonce = NACL.randomBytes(24)
    [uniqueNonce, {
      senderID: miniLockLib.ID.encode(@keys.publicKey)
      recipientID: miniLockID
      fileInfo: NACL.util.encodeBase64(@encryptedFileInfo(miniLockID, uniqueNonce))
    }]
  
  encryptedFileInfo: (miniLockID, uniqueNonce) ->
    decodedFileInfoJSON = NACL.util.decodeUTF8(JSON.stringify(@permitFileInfo()))
    recipientPublicKey = miniLockLib.ID.decode(miniLockID)
    NACL.box(decodedFileInfoJSON, uniqueNonce, recipientPublicKey, @keys.secretKey)

  permitFileInfo: ->
    fileKey:   NACL.util.encodeBase64(@fileKey)
    fileNonce: NACL.util.encodeBase64(@fileNonce)
    fileHash:  NACL.util.encodeBase64(@hash.digest())

