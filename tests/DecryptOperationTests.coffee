Alice = window.testFixtures.Alice
Bobby = window.testFixtures.Bobby
readFileAsBlob = window.testFixtures.readFileAsBlob

T = window.DecryptOperationTests = {}

T["construct a blank decrypt operation"] = (test) ->
  operation = new miniLockLib.DecryptOperation
  test.ok operation
  test.done()

T["read length of header from a file encrypted with the miniLock App"] = (test) ->
  readFileAsBlob 'basic.txt.encrypted_with_minilock_app.minilock', (error, blob) ->
    operation = new miniLockLib.DecryptOperation data: blob
    operation.readLengthOfHeader (error, lengthOfHeader) ->
      test.ok lengthOfHeader is 634
      test.done()

T["read length of header from a file encrypted with miniLockLib"] = (test) ->
  readFileAsBlob 'basic.txt.encrypted_with_minilock_app.minilock', (error, blob) ->
    operation = new miniLockLib.DecryptOperation data: blob
    operation.readLengthOfHeader (error, lengthOfHeader) ->
      test.ok lengthOfHeader is 634
      test.done()

T["read header from a file encrypted with the miniLock App"] = (test) ->
  readFileAsBlob 'basic.txt.encrypted_with_minilock_app.minilock', (error, blob) ->
    operation = new miniLockLib.DecryptOperation data: blob
    operation.readHeader (error, header) ->
      test.ok header.constructor is Object
      test.ok header.version is 1
      test.ok header.ephemeral is "GxM6P7EJC93kZRjHN2zzrRAL/ARhZPg+gxPe13MDKiQ="
      test.ok header.decryptInfo['uQP3fG1m02LtR/bJa4EDB0jX6FNz81bf'].constructor is String
      test.ok header.decryptInfo['uQP3fG1m02LtR/bJa4EDB0jX6FNz81bf'].length is 508
      test.done()

T["read header from a file encrypted with miniLockLib"] = (test) ->
  readFileAsBlob 'basic.txt.encrypted_with_minilocklib.minilock', (error, blob) ->
    operation = new miniLockLib.DecryptOperation data: blob
    operation.readHeader (error, header) ->
      test.ok header.constructor is Object
      test.ok header.version is 1
      test.ok header.ephemeral is "SxARGdK7LLUyPf8aSyJP/Klnj0c2HzMvmf1HqPtcCwg="
      test.ok header.decryptInfo['CyN3GTzDxKR0elLrLJ0csSvX5/z2O7Cr'].constructor is String
      test.ok header.decryptInfo['CyN3GTzDxKR0elLrLJ0csSvX5/z2O7Cr'].length is 508
      test.done()

T["decrypt uniqueNonce and permit from a file encrypted with miniLock App"] = (test) ->
  readFileAsBlob 'basic.txt.encrypted_with_minilock_app.minilock', (error, blob) ->
    operation = new miniLockLib.DecryptOperation
      data: blob
      keys: Alice.keys
    operation.decryptUniqueNonceAndPermit (error, uniqueNonce, permit, lengthOfHeader) ->
      if error? then return test.done(error)
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
      test.done()

T["decrypt uniqueNonce and permit from a file encrypted with miniLockLib"] = (test) ->
  readFileAsBlob 'basic.txt.encrypted_with_minilocklib.minilock', (error, blob) ->
    operation = new miniLockLib.DecryptOperation
      data: blob
      keys: Alice.keys
    operation.decryptUniqueNonceAndPermit (error, uniqueNonce, permit, lengthOfHeader) ->
      if error? then return test.done(error)
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
      test.done()

T["decrypt file name from a file encrypted with the miniLock App"] = (test) ->
  readFileAsBlob 'basic.txt.encrypted_with_minilock_app.minilock', (error, blob) ->
    operation = new miniLockLib.DecryptOperation
      data: blob
      keys: Alice.keys
    operation.decryptName (error, nameWasDecrypted, positionOfLastNameByte) ->
      test.ok nameWasDecrypted is true
      test.ok operation.name is 'basic.txt'
      test.ok positionOfLastNameByte is 922
      test.done(error)

T["decrypt file name from a file encrypted with the miniLockLib"] = (test) ->
  readFileAsBlob 'basic.txt.encrypted_with_minilocklib.minilock', (error, blob) ->
    operation = new miniLockLib.DecryptOperation
      data: blob
      keys: Alice.keys
    operation.decryptName (error, nameWasDecrypted, positionOfLastNameByte) ->
      test.ok nameWasDecrypted is true
      test.ok operation.name is 'basic.txt'
      test.ok positionOfLastNameByte is 922
      test.done(error)

T["decrypt a file encrypted with the miniLock App"] = (test) ->
  readFileAsBlob 'basic.txt.encrypted_with_minilock_app.minilock', (error, blob) ->
    operation = new miniLockLib.DecryptOperation
      data: blob
      keys: Alice.keys
    operation.start (error, decrypted) ->
      return test.done(error) if error?
      test.ok decrypted.data.constructor is Blob
      test.ok decrypted.data.size is 20
      test.ok decrypted.name is "basic.txt"
      test.ok decrypted.senderID is Alice.miniLockID
      test.ok decrypted.recipientID is Alice.miniLockID
      test.done()

T["decrypt a file encrypted with miniLockLib"] = (test) ->
  readFileAsBlob 'basic.txt.encrypted_with_minilocklib.minilock', (error, blob) ->
    operation = new miniLockLib.DecryptOperation
      data: blob
      keys: Alice.keys
    operation.start (error, decrypted) ->
      return test.done(error) if error?
      test.ok decrypted.data.constructor is Blob
      test.ok decrypted.data.size is 20
      test.ok decrypted.name is "basic.txt"
      test.ok decrypted.senderID is Alice.miniLockID
      test.ok decrypted.recipientID is Alice.miniLockID
      test.done()

T["decrypt 1MB file for Alice"] = (test) ->
  readFileAsBlob '1MB.tiff.for.Alice.minilock', (error, blob) ->
    operation = new miniLockLib.DecryptOperation
      data: blob
      keys: Alice.keys
    operation.start (error, decrypted) ->
      return test.done(error) if error?
      test.ok decrypted.data.constructor is Blob
      test.ok decrypted.data.size is 1048826
      test.ok decrypted.name is "1MB.tiff"
      test.ok decrypted.senderID is Alice.miniLockID
      test.ok decrypted.recipientID is Alice.miniLockID
      test.done()

T["decrypt 4MB file for Alice"] = (test) ->
  readFileAsBlob '4MB.tiff.for.Alice.minilock', (error, blob) ->
    operation = new miniLockLib.DecryptOperation
      data: blob
      keys: Alice.keys
    operation.start (error, decrypted) ->
      return test.done(error) if error?
      test.ok decrypted.data.constructor is Blob
      test.ok decrypted.data.size is 4194746
      test.ok decrypted.name is "4MB.tiff"
      test.ok decrypted.senderID is Alice.miniLockID
      test.ok decrypted.recipientID is Alice.miniLockID
      test.done()
