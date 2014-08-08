tape = require "./tape_test_harness"
{Alice, Bobby, read, readFromNetwork} = require "./fixtures"

tape "Slow Operations", (test) -> test.end()

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

tape "encrypt 1MB file for Alice", (test) ->
  readFromNetwork "1MB.tiff", (blob) ->
    operation = new miniLockLib.EncryptOperation
      data: blob
      name: "alice.1MB.tiff"
      keys: Alice.keys
      miniLockIDs: [Alice.miniLockID]
    operation.start (error, encrypted) ->
      if error? then return test.end(error)
      test.ok encrypted.data.size is 1049788
      test.ok encrypted.name is "alice.1MB.tiff.minilock"
      test.ok encrypted.senderID is Alice.miniLockID
      test.end()
      console.info("encrypted", encrypted.name, encrypted)

tape "encrypt 4MB file for Alice", (test) ->
  readFromNetwork "4MB.tiff", (blob) ->
    operation = new miniLockLib.EncryptOperation
      data: blob
      name: "alice.4MB.tiff"
      keys: Alice.keys
      miniLockIDs: [Alice.miniLockID]
    operation.start (error, encrypted) ->
      if error? then return test.end(error)
      test.ok encrypted.data.size is 4195768
      test.ok encrypted.name is "alice.4MB.tiff.minilock"
      test.ok encrypted.senderID is Alice.miniLockID
      test.end()
      console.info("encrypted", encrypted.name, encrypted)
