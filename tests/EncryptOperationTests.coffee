window.testCases.push(T={})

{Alice, Bobby, read, readFromNetwork} = window.testFixtures

T["construct a blank encrypt operation"] = (test) ->
  operation = new miniLockLib.EncryptOperation
  test.ok operation
  test.done()

T["author is available after operation is constructed"] = (test) ->
  operation = new miniLockLib.EncryptOperation
  test.ok operation.author?
  test.done()

T["empty array of ciphertext bytes is ready after operation is constructed"] = (test) ->
  operation = new miniLockLib.EncryptOperation
  test.ok operation.ciphertextBytes.length is 0
  test.done()

T["ephemeral key pair is ready after operation is constructed"] = (test) ->
  operation = new miniLockLib.EncryptOperation
  test.ok operation.ephemeral.publicKey?
  test.ok operation.ephemeral.secretKey?
  test.done()

T["file key is ready after operation is constructed"] = (test) ->
  operation = new miniLockLib.EncryptOperation
  test.ok operation.fileKey.constructor is Uint8Array
  test.ok operation.fileKey.length is 32
  test.done()

T["file nonce is ready after operation is constructed"] = (test) ->
  operation = new miniLockLib.EncryptOperation
  test.ok operation.fileNonce.constructor is Uint8Array
  test.ok operation.fileNonce.length is 16
  test.done()
  
T["hash for ciphertext bytes is ready after operation is constructed"] = (test) ->
  operation = new miniLockLib.EncryptOperation
  test.ok operation.hash.constructor is BLAKE2s
  test.ok operation.hash.digestLength is 32 # bytes
  test.ok operation.hash.isFinished is false
  test.ok operation.hash.update?
  test.ok operation.hash.digest?
  test.done()

T["decoded name has a fixed length of 256 bytes"] = (test) ->
  operation = new miniLockLib.EncryptOperation name: "untitled.txt"
  decodedName = operation.fixedLengthDecodedName()
  test.same decodedName.length, 256
  test.done()

T["encrypt name of a file"] = (test) ->
  operation = new miniLockLib.EncryptOperation name: "untitled.txt"
  operation.encryptName()
  test.ok operation.ciphertextBytes.length is 1
  decryptor = nacl.stream.createDecryptor(operation.fileKey, operation.fileNonce, operation.chunkSize)
  decryptedChunk = decryptor.decryptChunk(operation.ciphertextBytes[0], no)
  test.ok decryptedChunk?
  decryptedName = nacl.util.encodeUTF8(decryptedChunk)
  test.ok decryptedName.length is 256
  test.ok decryptedName.indexOf("untitled.txt") is 0
  test.done()

T["construct a permit to decrypt for a recipient"] = (test) ->
  operation = new miniLockLib.EncryptOperation keys: Alice.keys
  [uniqueNonce, permit] = operation.permit(Bobby.miniLockID)
  test.ok uniqueNonce.constructor is Uint8Array
  test.ok uniqueNonce.length is 24
  test.ok permit.senderID is Alice.miniLockID
  test.ok permit.recipientID is Bobby.miniLockID
  test.ok permit.fileInfo.constructor is String
  test.ok permit.fileInfo isnt ""
  test.done()
  
T["recipient can decrypt the key, nonce and hash of the file encoded in their permit"] = (test) ->
  operation = new miniLockLib.EncryptOperation keys: Alice.keys
  [uniqueNonce, permit] = operation.permit(Bobby.miniLockID)
  decodedFileInfo = nacl.util.decodeBase64(permit.fileInfo)
  decryptedFileInfo = nacl.box.open(decodedFileInfo, uniqueNonce, Alice.publicKey, Bobby.secretKey)
  test.ok decryptedFileInfo
  fileInfo = JSON.parse(nacl.util.encodeUTF8(decryptedFileInfo))
  test.ok fileInfo.fileKey?
  test.ok fileInfo.fileNonce?
  test.ok fileInfo.fileHash is "aSF6MHmQgJThESHQQjVKfB9VtkgsoaUeGyUN/R7Q7vk="
  test.done()

T["header specifies version 1 of the miniLock file format"] = (test) ->
  operation = new miniLockLib.EncryptOperation
    keys: Alice.keys
    miniLockIDs: [Alice.miniLockID]
  operation.constructHeader()
  test.ok operation.header.version is 1
  test.done()

T["header has a Base64 encoded 32-byte ephemeral key"] = (test) ->
  operation = new miniLockLib.EncryptOperation
    keys: Alice.keys
    miniLockIDs: [Alice.miniLockID]
  operation.constructHeader()
  test.ok nacl.util.decodeBase64(operation.header.ephemeral).length is 32
  test.done()

T["header for one recipient has one permit"] = (test) ->
  operation = new miniLockLib.EncryptOperation
    keys: Alice.keys
    miniLockIDs: [Alice.miniLockID]
  operation.constructHeader()
  test.ok Object.keys(operation.header.decryptInfo).length is 1
  test.done()

T["header for two recipients has two permits"] = (test) ->
  operation = new miniLockLib.EncryptOperation
    keys: Alice.keys
    miniLockIDs: [Alice.miniLockID, Bobby.miniLockID]
  operation.constructHeader()
  test.ok Object.keys(operation.header.decryptInfo).length is 2
  test.done()

T["encrypt 1MB file for Alice"] = (test) ->
  readFromNetwork "1MB.tiff", (blob) ->
    operation = new miniLockLib.EncryptOperation
      data: blob
      name: "alice.1MB.tiff"
      keys: Alice.keys
      miniLockIDs: [Alice.miniLockID]
    operation.start (error, encrypted) ->
      if error? then return test.done(error)
      test.ok encrypted.data.size is 1049788
      test.ok encrypted.name is "alice.1MB.tiff.minilock"
      test.ok encrypted.senderID is Alice.miniLockID
      test.done()
      console.info("encrypted", encrypted.name, encrypted)

T["encrypt 4MB file for Alice"] = (test) ->
  readFromNetwork "4MB.tiff", (blob) ->
    operation = new miniLockLib.EncryptOperation
      data: blob
      name: "alice.4MB.tiff"
      keys: Alice.keys
      miniLockIDs: [Alice.miniLockID]
    operation.start (error, encrypted) ->
      if error? then return test.done(error)
      test.ok encrypted.data.size is 4195768
      test.ok encrypted.name is "alice.4MB.tiff.minilock"
      test.ok encrypted.senderID is Alice.miniLockID
      test.done()
      console.info("encrypted", encrypted.name, encrypted)

