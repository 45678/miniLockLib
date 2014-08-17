AbstractOperation = require("./AbstractOperation")
NACL = require("./NACL")
BLAKE2s = require("./BLAKE2s")
{numberToByteArray} = require("./util")

class EncryptOperation extends AbstractOperation
  module.exports = this

  constructor: (params={})->
    {@data, @keys, @name, @type, @time, @miniLockIDs, @version, @callback} = params
    @version = 1 if @version is undefined
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
    if (@data instanceof Blob) is false
      throw "Can’t start miniLockLib.#{@constructor.name} without data."
    if typeof @callback isnt "function"
      throw "Can’t start miniLockLib.#{@constructor.name} without a callback."
    @startedAt = Date.now()
    @time = @startedAt if @time is undefined
    @run()

  run: ->
    @encryptAttributes(@version)
    @encryptData 0, (error, dataWasEncrypted) =>
      if dataWasEncrypted?
        @constructHeader()
        fileFormat = [
          "miniLock"
          @sizeOfHeaderIn4Bytes
          @headerJSONBytes
          @ciphertextBytes...
        ]
        @end(error, new Blob fileFormat, type: "application/minilock")
      else
        @end(error)

  end: (error, blob) =>
    @streamEncryptor.clean() if @streamEncryptor?
    AbstractOperation::end.call(this, error, blob)

  oncomplete: (blob) ->
    @callback(undefined, {
      data: blob
      name: @name + ".minilock"
      type: @type
      time: @time
      senderID: miniLockLib.ID.encode(@keys.publicKey)
      duration: @duration
      startedAt: @startedAt
      endedAt: @endedAt
    })

  onerror: (error) ->
    @callback(error)

  encryptAttributes: (version) ->
    @constructStreamEncryptor()
    bytes = switch version
      when 1 then new Uint8Array 256
      when 2 then new Uint8Array 256+128+24
      else throw "EncryptOperation does not support version #{version}. Version 1 or 2 please."
    bytes.set @fixedSizeDecodedName(), 0
    bytes.set @fixedSizeDecodedType(), 256 if version is 2
    bytes.set @fixedSizeDecodedTime(), 256+128 if version is 2
    if encryptedBytes = @streamEncryptor.encryptChunk(bytes, no)
      @hash.update(encryptedBytes)
      @ciphertextBytes.push(encryptedBytes)
    else
      throw "EncryptOperation failed to record file attributes."

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
      version: @version
      ephemeral: NACL.util.encodeBase64(@ephemeral.publicKey)
      decryptInfo: @encodedEncryptedPermits()
    headerJSON = JSON.stringify(@header)
    @sizeOfHeaderIn4Bytes = numberToByteArray(headerJSON.length)
    @headerJSONBytes = NACL.util.decodeUTF8(headerJSON)
    return @header

  constructStreamEncryptor: ->
    @streamEncryptor ?= NACL.stream.createEncryptor(@fileKey, @fileNonce, @chunkSize)

  fixedSizeDecodedName: ->
    fixedSize = new Uint8Array(256)
    if @name
      decodedName = NACL.util.decodeUTF8(@name)
      if decodedName.length > fixedSize.length
        throw "EncryptOperation file name is too long. 256-characters max please."
      fixedSize.set(decodedName)
    return fixedSize

  fixedSizeDecodedType: ->
    fixedSize = new Uint8Array(128)
    if @type
      decodedType = NACL.util.decodeUTF8(@type)
      if decodedType.length > fixedSize.length
        throw "EncryptOperation media type is too long. 128-characters max please."
      fixedSize.set(decodedType)
    return fixedSize

  fixedSizeDecodedTime: ->
    fixedSize = new Uint8Array(24)
    if @time
      timestamp = (new Date(@time)).toJSON()
      fixedSize.set(NACL.util.decodeUTF8(timestamp))
    return fixedSize

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
