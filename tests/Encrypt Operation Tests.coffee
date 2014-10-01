tape = require "./tape_test_harness"
{Alice, Bobby, read, readFromNetwork} = require "./fixtures"

tape "EncryptOperation", (test) -> test.end()

tape "construct a blank encrypt operation", (test) ->
  operation = new miniLockLib.EncryptOperation
  test.ok operation
  test.end()

tape "make miniLock version 1 files by default", (test) ->
  operation = new miniLockLib.EncryptOperation
  test.same operation.version, 1
  test.end()

tape "define version, data, name, type, time, miniLockIDs, keys and callback when you construct an encrypt operation", (test) ->
  operation = new miniLockLib.EncryptOperation
    version: 2
    data: data = new Blob
    name: "secret.minilock"
    type: "text/plain"
    time: time = Date.now()
    miniLockIDs: miniLockIDs = []
    keys: Alice.keys
    callback: callback = (error, encrypted) ->
  test.same operation.version, 2
  test.same operation.data, data
  test.same operation.name, "secret.minilock"
  test.same operation.type, "text/plain"
  test.same operation.time, time
  test.same operation.keys, Alice.keys
  test.same operation.miniLockIDs, miniLockIDs
  test.same operation.callback, callback
  test.end()

tape "can’t start encrypt operation without callback function", (test) ->
  operation = new miniLockLib.EncryptOperation
  test.throws operation.start, 'Can’t start encrypt operation without callback function.'
  test.end()

tape "can’t start encrypt operation without data", (test) ->
  operation = new miniLockLib.EncryptOperation
    keys: Alice.keys
    miniLockIDs: []
  operation.start (error, encrypted) ->
    test.same error, "Can’t encrypt without a Blob of data."
    test.same encrypted, undefined
    test.end()

tape "can’t start encrypt operation with data that is not a Blob", (test) ->
  operation = new miniLockLib.EncryptOperation
    data: "Not a blob"
    keys: Alice.keys
    miniLockIDs: []
  operation.start (error, encrypted) ->
    test.same error, "Can’t encrypt without a Blob of data."
    test.same encrypted, undefined
    test.end()

tape "can’t start encrypt operation without a set of keys", (test) ->
  operation = new miniLockLib.EncryptOperation
    data: new Blob
    miniLockIDs: []
  operation.start (error, encrypted) ->
    test.same error, "Can’t encrypt without a set of keys."
    test.same encrypted, undefined
    test.end()

tape "can’t start encrypt operation without miniLock IDs", (test) ->
  operation = new miniLockLib.EncryptOperation
    data: new Blob
    keys: Alice.keys
  operation.start (error, encrypted) ->
    test.same error, 'Can’t encrypt without an Array of miniLock IDs.'
    test.same encrypted, undefined
    test.end()

tape "can’t start encrypt operation with unacceptable file name", (test) ->
  operation = new miniLockLib.EncryptOperation
    data: new Blob
    keys: Alice.keys
    miniLockIDs: []
    name: ("X" for i in [0...257]).join("") # Make a string that is 257 characters long.
  operation.start (error, encrypted) ->
    test.same error, "Can’t encrypt because file name is too long. 256-characters max please."
    test.same encrypted, undefined
    test.end()

tape "can’t start encrypt operation with unacceptable media type", (test) ->
  operation = new miniLockLib.EncryptOperation
    data: new Blob
    keys: Alice.keys
    miniLockIDs: []
    type: ("X" for i in [0...129]).join("") # Make a string that is 129 characters long.
  operation.start (error, encrypted) ->
    test.same error, "Can’t encrypt because media type is too long. 128-characters max please."
    test.same encrypted, undefined
    test.end()

tape "can’t start encrypt operation with unacceptable file format version", (test) ->
  operation = new miniLockLib.EncryptOperation
    data: new Blob
    keys: Alice.keys
    miniLockIDs: []
    version: 0
  operation.start (error, encrypted) ->
    test.same error, "Can’t encrypt because version 0 is not supported. Version 1 or 2 please."
    test.same encrypted, undefined
    test.end()

tape "empty array of ciphertext bytes is ready after operation is constructed", (test) ->
  operation = new miniLockLib.EncryptOperation
  test.ok operation.ciphertextBytes.length is 0
  test.end()

tape "ephemeral key pair is ready after operation is constructed", (test) ->
  operation = new miniLockLib.EncryptOperation
  test.ok operation.ephemeral.publicKey?
  test.ok operation.ephemeral.secretKey?
  test.end()

tape "file key is ready after operation is constructed", (test) ->
  operation = new miniLockLib.EncryptOperation
  test.ok operation.fileKey.constructor is Uint8Array
  test.ok operation.fileKey.length is 32
  test.end()

tape "file nonce is ready after operation is constructed", (test) ->
  operation = new miniLockLib.EncryptOperation
  test.ok operation.fileNonce.constructor is Uint8Array
  test.ok operation.fileNonce.length is 16
  test.end()

tape "hash for ciphertext bytes is ready after operation is constructed", (test) ->
  operation = new miniLockLib.EncryptOperation
  test.ok operation.hash.digestLength is 32 # bytes
  test.ok operation.hash.isFinished is false
  test.ok operation.hash.update?
  test.ok operation.hash.digest?
  test.end()

tape "name has a fixed size of 256 bytes", (test) ->
  operation = new miniLockLib.EncryptOperation name: "untitled.txt"
  decodedName = operation.fixedSizeDecodedName()
  test.equal decodedName.length, 256
  test.end()

tape "undefined name has a fixed size of 256 bytes", (test) ->
  operation = new miniLockLib.EncryptOperation name: undefined
  decodedName = operation.fixedSizeDecodedName()
  test.equal decodedName.length, 256
  filteredBytes = (byte for byte in decodedName when byte isnt 0)
  test.same filteredBytes.length, 0
  test.end()

tape "decoded type has a fixed size of 128 bytes", (test) ->
  operation = new miniLockLib.EncryptOperation type: "text/plain"
  decodedType = operation.fixedSizeDecodedType()
  test.equal decodedType.length, 128
  test.end()

tape "decoded time has a fixed size of 24 bytes", (test) ->
  operation = new miniLockLib.EncryptOperation time: Date.now()
  decodedTime = operation.fixedSizeDecodedTime()
  test.equal decodedTime.length, 24
  test.end()

tape "encrypt version 1 attributes", (test) ->
  operation = new miniLockLib.EncryptOperation
    version: 1
    name: "untitled.txt"
  operation.encryptAttributes(1)
  test.same operation.ciphertextBytes.length, 1
  decryptor = miniLockLib.NaCl.stream.createDecryptor(operation.fileKey, operation.fileNonce, operation.chunkSize+4+16)
  decryptedBytes = decryptor.decryptChunk(operation.ciphertextBytes[0], no)
  test.equal decryptedBytes.length, 256
  filteredBytes = (byte for byte in decryptedBytes when byte isnt 0)
  decryptedName = miniLockLib.NaCl.util.encodeUTF8(filteredBytes)
  test.equal decryptedName, "untitled.txt"
  test.end()

tape "encrypt version 2 attributes", (test) ->
  operation = new miniLockLib.EncryptOperation
    version: 2
    name: "untitled.txt"
    type: "text/plain"
    time: (new Date "2014-08-17T07:06:50.095Z").getTime()
  operation.encryptAttributes(2)
  test.same operation.ciphertextBytes.length, 1
  decryptor = miniLockLib.NaCl.stream.createDecryptor(operation.fileKey, operation.fileNonce, operation.chunkSize+4+16)
  decryptedBytes = decryptor.decryptChunk(operation.ciphertextBytes[0], no)
  test.equal decryptedBytes.length, 256+128+24

  decryptedNameBytes = decryptedBytes.subarray(0, 256)
  filteredNameBytes = (byte for byte in decryptedNameBytes when byte isnt 0)
  decryptedName = miniLockLib.NaCl.util.encodeUTF8(filteredNameBytes)
  test.equal decryptedName, "untitled.txt"

  decryptedTypeBytes = decryptedBytes.subarray(256, 256+128)
  filteredTypeBytes = (byte for byte in decryptedTypeBytes when byte isnt 0)
  decryptedType = miniLockLib.NaCl.util.encodeUTF8(filteredTypeBytes)
  test.equal decryptedType, "text/plain"

  decryptedTimeBytes = decryptedBytes.subarray(256+128, 256+128+24)
  filteredTimeBytes = (byte for byte in decryptedTimeBytes when byte isnt 0)
  decryptedTime = miniLockLib.NaCl.util.encodeUTF8(filteredTimeBytes)
  test.equal decryptedTime, "2014-08-17T07:06:50.095Z"
  test.end()

tape "construct a permit to decrypt for a recipient", (test) ->
  operation = new miniLockLib.EncryptOperation keys: Alice.keys
  [uniqueNonce, permit] = operation.permit(Bobby.miniLockID)
  test.ok uniqueNonce.constructor is Uint8Array
  test.ok uniqueNonce.length is 24
  test.ok permit.senderID is Alice.miniLockID
  test.ok permit.recipientID is Bobby.miniLockID
  test.ok permit.fileInfo.constructor is String
  test.ok permit.fileInfo isnt ""
  test.end()

tape "recipient can decrypt the key, nonce and hash of the file encoded in their permit", (test) ->
  operation = new miniLockLib.EncryptOperation keys: Alice.keys
  [uniqueNonce, permit] = operation.permit(Bobby.miniLockID)
  decodedFileInfo = miniLockLib.NaCl.util.decodeBase64(permit.fileInfo)
  decryptedFileInfo = miniLockLib.NaCl.box.open(decodedFileInfo, uniqueNonce, Alice.publicKey, Bobby.secretKey)
  test.ok decryptedFileInfo
  fileInfo = JSON.parse(miniLockLib.NaCl.util.encodeUTF8(decryptedFileInfo))
  test.ok fileInfo.fileKey?
  test.ok fileInfo.fileNonce?
  test.ok fileInfo.fileHash is "aSF6MHmQgJThESHQQjVKfB9VtkgsoaUeGyUN/R7Q7vk="
  test.end()

tape "header specifies version 1 of the miniLock file format", (test) ->
  operation = new miniLockLib.EncryptOperation
    keys: Alice.keys
    miniLockIDs: [Alice.miniLockID]
  operation.constructHeader()
  test.ok operation.header.version is 1
  test.end()

tape "header has a Base64 encoded 32-byte ephemeral key", (test) ->
  operation = new miniLockLib.EncryptOperation
    keys: Alice.keys
    miniLockIDs: [Alice.miniLockID]
  operation.constructHeader()
  test.ok miniLockLib.NaCl.util.decodeBase64(operation.header.ephemeral).length is 32
  test.end()

tape "header for one recipient has one permit", (test) ->
  operation = new miniLockLib.EncryptOperation
    keys: Alice.keys
    miniLockIDs: [Alice.miniLockID]
  operation.constructHeader()
  test.ok Object.keys(operation.header.decryptInfo).length is 1
  test.end()

tape "header for two recipients has two permits", (test) ->
  operation = new miniLockLib.EncryptOperation
    keys: Alice.keys
    miniLockIDs: [Alice.miniLockID, Bobby.miniLockID]
  operation.constructHeader()
  test.ok Object.keys(operation.header.decryptInfo).length is 2
  test.end()
