

{Alice, Bobby, read, readFromNetwork, tape} = require "./_fixtures"

tape "DecryptOperation Tests", (test) -> test.end()

tape "construct a blank miniLockLib.DecryptOperation", (test) ->
  operation = new miniLockLib.DecryptOperation
  test.ok operation
  test.equal operation.constructor, miniLockLib.DecryptOperation
  test.end()

tape "read length of header from a file", (test) ->
  read "alice.txt.minilock", (blob) ->
    operation = new miniLockLib.DecryptOperation
      data: blob
    operation.readLengthOfHeader (error, lengthOfHeader) ->
      test.equal lengthOfHeader, 634
      test.end()

tape "read header of file with one permits", (test) ->
  read "alice.txt.minilock", (blob) ->
    operation = new miniLockLib.DecryptOperation
      data: blob
    operation.readHeader (error, header) ->
      if error then return test.end(error)
      test.ok header.version is 1
      test.ok header.ephemeral.constructor is String
      test.ok header.ephemeral.length is 44
      uniqueNonces = Object.keys(header.decryptInfo)
      test.ok uniqueNonces.length is 1
      test.ok header.decryptInfo[uniqueNonces[0]].length is 508
      test.end()

tape "read header of file with two permits", (test) ->
  read "alice_and_bobby.txt.minilock", (blob) ->
    operation = new miniLockLib.DecryptOperation
      data: blob
    operation.readHeader (error, header) ->
      if error then return test.end(error)
      test.ok header.version is 1
      test.ok header.ephemeral.constructor is String
      test.ok header.ephemeral.length is 44
      uniqueNonces = Object.keys(header.decryptInfo)
      test.ok uniqueNonces.length is 2
      test.ok header.decryptInfo[uniqueNonces[0]].length is 508
      test.ok header.decryptInfo[uniqueNonces[1]].length is 508
      test.end()

tape "decrypt uniqueNonce and permit from a file encrypted with miniLockLib", (test) ->
  read "alice.txt.minilock", (blob) ->
    operation = new miniLockLib.DecryptOperation
      data: blob
      keys: Alice.keys
    operation.decryptUniqueNonceAndPermit (error, uniqueNonce, permit, lengthOfHeader) ->
      if error? then return test.end(error)
      test.ok uniqueNonce
      test.ok uniqueNonce.constructor is Uint8Array
      test.ok uniqueNonce.length is 24
      test.ok permit.senderID is Alice.miniLockID
      test.ok permit.recipientID is Alice.miniLockID
      test.ok permit.fileInfo.fileHash?
      test.ok permit.fileInfo.fileKey.constructor is Uint8Array
      test.ok permit.fileInfo.fileKey.length is 32
      test.ok permit.fileInfo.fileNonce.constructor is Uint8Array
      test.ok permit.fileInfo.fileNonce.length is 16
      test.ok lengthOfHeader is 634
      test.end()

tape "decrypt file name", (test) ->
  read "alice.txt.minilock", (blob) ->
    operation = new miniLockLib.DecryptOperation
      data: blob
      keys: Alice.keys
    operation.decryptName (error, nameWasDecrypted, positionOfLastNameByte) ->
      test.ok nameWasDecrypted is true
      test.ok operation.name is "alice.txt"
      test.ok positionOfLastNameByte is 922
      test.end(error)

tape "decrypt 1MB file for Alice", (test) ->
  readFromNetwork "1MB.tiff.for.Alice.minilock", (blob) ->
    operation = new miniLockLib.DecryptOperation
      data: blob
      keys: Alice.keys
    operation.start (error, decrypted) ->
      if error? then return test.end(error)
      test.ok decrypted.data.size is 1048826
      test.ok decrypted.name is "1MB.tiff"
      test.ok decrypted.senderID is Alice.miniLockID
      test.ok decrypted.recipientID is Alice.miniLockID
      test.end()
      console.info("decrypted", decrypted.name, decrypted)

tape "decrypt 4MB file for Alice", (test) ->
  readFromNetwork "4MB.tiff.for.Alice.minilock", (blob) ->
    operation = new miniLockLib.DecryptOperation
      data: blob
      keys: Alice.keys
    operation.start (error, decrypted) ->
      if error? then return test.end(error)
      test.ok decrypted.data.size is 4194746
      test.ok decrypted.name is "4MB.tiff"
      test.ok decrypted.senderID is Alice.miniLockID
      test.ok decrypted.recipientID is Alice.miniLockID
      test.end()
      console.info("decrypted", decrypted.name, decrypted)
