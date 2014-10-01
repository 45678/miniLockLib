module.exports = class EncryptOperation
  NaCl = require "./NaCl"
  BLAKE2s = require "./BLAKE2s"
  {numberToByteArray} = require "./util"

  chunkSize: 1024 * 1024
  readSliceOfData: require "./readSliceOfData"

  constructor: (params={})->
    {@data, @keys, @name, @type, @time, @miniLockIDs, @version, @callback} = params
    @version = 1 if @version is undefined
    @ephemeral = NaCl.box.keyPair()
    @fileKey = NaCl.randomBytes(32)
    @fileNonce = NaCl.randomBytes(24).subarray(0, 16)
    @hash = new BLAKE2s(32)
    @ciphertextBytes = []
    @start() if params.start?

  start: (callback) =>
    @callback = callback if callback?
    if @callback?.constructor isnt Function
      throw "Can’t start encrypt operation without callback function."
    switch
      when (@data instanceof Blob) is no
        @callback "Can’t encrypt without a Blob of data."
      when (@keys?.publicKey is undefined) or (@keys?.secretKey is undefined)
        @callback "Can’t encrypt without a set of keys."
      when (@miniLockIDs instanceof Array) is no
        @callback "Can’t encrypt without an Array of miniLock IDs."
      when @name and @name.length > 256
        @callback "Can’t encrypt because file name is too long. 256-characters max please."
      when @type and @type.length > 128
        @callback "Can’t encrypt because media type is too long. 128-characters max please."
      when (@version in [1, 2]) is no
        @callback "Can’t encrypt because version #{@version} is not supported. Version 1 or 2 please."
      else
        @startedAt = Date.now()
        @time = @startedAt if @time is undefined
        @run()
    return this

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
    @endedAt = Date.now()
    @duration = @endedAt - @startedAt
    if error
      @onerror(error)
    else
      @oncomplete(blob)

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
        callback "Failed to encrypt slice of data at [#{position}..#{position+@chunkSize}]"

  constructHeader: ->
    @header =
      version: @version
      ephemeral: NaCl.util.encodeBase64(@ephemeral.publicKey)
      decryptInfo: @encodedEncryptedPermits()
    headerJSON = JSON.stringify(@header)
    @sizeOfHeaderIn4Bytes = numberToByteArray(headerJSON.length)
    @headerJSONBytes = NaCl.util.decodeUTF8(headerJSON)
    return @header

  constructStreamEncryptor: ->
    @streamEncryptor ?= NaCl.stream.createEncryptor(@fileKey, @fileNonce, @chunkSize)

  fixedSizeDecodedName: ->
    fixedSize = new Uint8Array(256)
    if @name
      decodedName = NaCl.util.decodeUTF8(@name)
      if decodedName.length > fixedSize.length
        throw "Can’t set fixed size decoded name because input is too long."
      fixedSize.set(decodedName)
    return fixedSize

  fixedSizeDecodedType: ->
    fixedSize = new Uint8Array(128)
    if @type
      decodedType = NaCl.util.decodeUTF8(@type)
      if decodedType.length > fixedSize.length
        throw "Can’t set fixed size decoded type because input is too long."
      fixedSize.set(decodedType)
    return fixedSize

  fixedSizeDecodedTime: ->
    fixedSize = new Uint8Array(24)
    if @time
      timestamp = (new Date(@time)).toJSON()
      fixedSize.set(NaCl.util.decodeUTF8(timestamp))
    return fixedSize

  encodedEncryptedPermits: ->
    permits = {}
    for miniLockID in @miniLockIDs
      [uniqueNonce, encryptedPermit] = @encryptedPermit(miniLockID)
      encodedUniqueNonce = NaCl.util.encodeBase64(uniqueNonce)
      encodedEncryptedPermit = NaCl.util.encodeBase64(encryptedPermit)
      permits[encodedUniqueNonce] = encodedEncryptedPermit
    return permits

  encryptedPermit: (miniLockID) ->
    [uniqueNonce, permit] = @permit(miniLockID)
    decodedPermitJSON = NaCl.util.decodeUTF8(JSON.stringify(permit))
    recipientPublicKey = miniLockLib.ID.decode(miniLockID)
    encryptedPermit = NaCl.box(decodedPermitJSON, uniqueNonce, recipientPublicKey, @ephemeral.secretKey)
    [uniqueNonce, encryptedPermit]

  permit: (miniLockID) ->
    uniqueNonce = NaCl.randomBytes(24)
    [uniqueNonce, {
      senderID: miniLockLib.ID.encode(@keys.publicKey)
      recipientID: miniLockID
      fileInfo: NaCl.util.encodeBase64(@encryptedFileInfo(miniLockID, uniqueNonce))
    }]

  encryptedFileInfo: (miniLockID, uniqueNonce) ->
    decodedFileInfoJSON = NaCl.util.decodeUTF8(JSON.stringify(@permitFileInfo()))
    recipientPublicKey = miniLockLib.ID.decode(miniLockID)
    NaCl.box(decodedFileInfoJSON, uniqueNonce, recipientPublicKey, @keys.secretKey)

  permitFileInfo: ->
    fileKey:   NaCl.util.encodeBase64(@fileKey)
    fileNonce: NaCl.util.encodeBase64(@fileNonce)
    fileHash:  NaCl.util.encodeBase64(@hash.digest())
