tape = require "./tape_test_harness"
{Alice, Bobby, read, readFromNetwork} = require "./fixtures"

tape "DecryptOperation", (test) -> test.end()

tape "construct a blank miniLockLib.DecryptOperation", (test) ->
  test.ok new miniLockLib.DecryptOperation
  test.end()

tape "define data, keys and callback when decrypt operation is constructed", (test) ->
  callback = (error, decrypted) ->
  operation = new miniLockLib.DecryptOperation
    data: (blob = new Blob)
    keys: Alice.keys
    callback: callback
  test.same operation.data, blob
  test.same operation.keys, Alice.keys
  test.same operation.callback, callback
  test.end()

tape "or define the callback when start is called if you prefer", (test) ->
  callbackSpecifiedOnStart = ->
  operation = new miniLockLib.DecryptOperation
    data: new Blob
    keys: Alice.keys
  # Intercept run to verify the expected callback and end the test.
  operation.run = ->
    test.same operation.callback, callbackSpecifiedOnStart
    test.end()
  operation.start(callbackSpecifiedOnStart)

tape "can’t start a decrypt operation without data", (test) ->
  operation = new miniLockLib.DecryptOperation
    keys: Alice.keys
    callback: yes
  test.throws operation.start, 'Can’t start miniLockLib.DecryptOperation without data.'
  test.end()

tape "can’t start a decrypt operation without keys", (test) ->
  operation = new miniLockLib.DecryptOperation
    data: yes
    callback: yes
  test.throws operation.start, 'Can’t start miniLockLib.DecryptOperation without keys.'
  test.end()

tape "can’t start a decrypt operation without a callback", (test) ->
  operation = new miniLockLib.DecryptOperation
    data: yes
    keys: Alice.keys
  test.throws operation.start, 'Can’t start miniLockLib.DecryptOperation without a callback.'
  test.end()

tape "construct map of byte addresses in a file", (test) ->
  read "alice.txt.minilock", (blob) ->
    operation = new miniLockLib.DecryptOperation
      data: blob
    operation.constructMap (error, map) ->
      test.same map, {
        magicBytes:         {start: 0,   end: 8  }
        sizeOfHeaderBytes:  {start: 8,   end: 12 }
        headerBytes:        {start: 12,  end: 646}
        ciphertextBytes:    {start: 646, end: 962}
        encryptedNameBytes: {start: 646, end: 646+256+4+16}
        encryptedDataBytes: {start: 646+256+4+16, end: 962}
      }
      test.end(error)

tape "read size of header", (test) ->
  read "alice.txt.minilock", (blob) ->
    operation = new miniLockLib.DecryptOperation
      data: blob
    operation.readSizeOfHeader (error, sizeOfHeader) ->
      test.equal sizeOfHeader, 634
      test.end()

tape "read header of a file with one permit", (test) ->
  read "alice.txt.minilock", (blob) ->
    operation = new miniLockLib.DecryptOperation
      data: blob
      keys: Alice.keys
    operation.readHeader (error, header) ->
      if error then return test.end(error)
      test.ok header.version is 1
      test.ok header.ephemeral.constructor is String
      test.ok header.ephemeral.length is 44
      uniqueNonces = Object.keys(header.decryptInfo)
      test.ok uniqueNonces.length is 1
      test.ok header.decryptInfo[uniqueNonces[0]].length is 508
      test.end()

tape "read header of a file with two permits", (test) ->
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

tape "decrypt uniqueNonce and permit", (test) ->
  read "alice.txt.minilock", (blob) ->
    operation = new miniLockLib.DecryptOperation
      data: blob
      keys: Alice.keys
    operation.decryptUniqueNonceAndPermit (error, uniqueNonce, permit) ->
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
      test.end()

tape "decrypt file name", (test) ->
  read "alice.txt.minilock", (blob) ->
    operation = new miniLockLib.DecryptOperation
      data: blob
      keys: Alice.keys
    operation.decryptName (error, name) ->
      test.same name, "alice.txt"
      test.end(error)
