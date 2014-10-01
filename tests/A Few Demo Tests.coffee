tape = require "./tape_test_harness"
{Alice, Bobby, read} = require "./fixtures"

tape "A demo of miniLockLib.encrypt & miniLockLib.decrypt", (test) -> test.end()

tape "Encrypt a version 1 file for Alice", (test) ->
  read "basic.txt", (blob) ->
    miniLockLib.encrypt
      version: 1
      data: blob
      name: "alice.txt.v1"
      keys: Alice.keys
      miniLockIDs: [Alice.miniLockID]
      callback: (error, encrypted) ->
        if error? then return test.end(error)
        test.ok encrypted.name is "alice.txt.v1.minilock"
        test.ok encrypted.data.size is 962
        test.ok encrypted.data.type is "application/minilock"
        test.ok encrypted.senderID is Alice.miniLockID
        test.end()

tape "Encrypt a version 2 file for Alice", (test) ->
  read "basic.txt", (blob) ->
    miniLockLib.encrypt
      version: 2
      data: blob
      name: "alice.txt.v2"
      keys: Alice.keys
      miniLockIDs: [Alice.miniLockID]
      callback: (error, encrypted) ->
        if error? then return test.end(error)
        test.same encrypted.name, "alice.txt.v2.minilock"
        test.same encrypted.data.size, 962+128+24
        test.same encrypted.data.type, "application/minilock"
        test.same encrypted.senderID, Alice.miniLockID
        test.end()

tape "Alice can decrypt version 1 file that was encrypted for her", (test) ->
  read "alice.txt.v1.minilock", (blob) ->
    miniLockLib.decrypt
      data: blob
      keys: Alice.keys
      callback: (error, decrypted) ->
        if error then return test.end(error)
        test.same decrypted.data.size, 20
        test.same decrypted.name, "alice.txt.v1"
        test.same decrypted.senderID, Alice.miniLockID
        test.same decrypted.recipientID, Alice.miniLockID
        test.end()

tape "Alice can decrypt version 2 file that was encrypted for her", (test) ->
  read "alice.txt.v2.minilock", (blob) ->
    miniLockLib.decrypt
      data: blob
      keys: Alice.keys
      callback: (error, decrypted) ->
        if error then return test.end(error)
        test.same decrypted.data.size, 20
        test.same decrypted.name, "alice.txt.v2"
        test.same decrypted.type, "text/plain"
        test.same decrypted.time, "2014-08-17T07:06:50.095Z"
        test.same decrypted.senderID, Alice.miniLockID
        test.same decrypted.recipientID, Alice.miniLockID
        test.end()

tape "Bobby can’t decrypt file that was only encrypted for Alice", (test) ->
  read "alice.txt.minilock", (blob) ->
    miniLockLib.decrypt
      data: blob
      keys: Bobby.keys
      callback: (error, decrypted) ->
        test.same error, "Can’t decrypt this file with this set of keys."
        test.same decrypted, undefined
        test.end()

tape "Encrypt a file for Alice & Bobby", (test) ->
  read "basic.txt", (blob) ->
    miniLockLib.encrypt
      data: blob
      name: "alice_and_bobby.txt"
      keys: Alice.keys
      miniLockIDs: [Alice.miniLockID, Bobby.miniLockID]
      callback: (error, encrypted) ->
        if error then return test.end(error)
        test.equal encrypted.name, "alice_and_bobby.txt.minilock"
        test.equal encrypted.data.size, 1508
        test.equal encrypted.data.type, "application/minilock"
        test.equal encrypted.senderID, Alice.miniLockID
        test.end()

tape "Alice can decrypt file that was encrypted for Alice & Bobby", (test) ->
  read "alice_and_bobby.txt.minilock", (blob) ->
    miniLockLib.decrypt
      data: blob
      keys: Alice.keys
      callback: (error, decrypted) ->
        if error then return test.end(error)
        test.same decrypted.data.size, 20
        test.same decrypted.name, "alice_and_bobby.txt"
        test.same decrypted.senderID, Alice.miniLockID
        test.same decrypted.recipientID, Alice.miniLockID
        test.end()

tape "Bobby can decrypt file that was encrypted for Alice & Bobby", (test) ->
  read "alice_and_bobby.txt.minilock", (blob) ->
    miniLockLib.decrypt
      data: blob
      keys: Bobby.keys
      callback: (error, decrypted) ->
        if error then return test.end(error)
        test.same decrypted.data.size, 20
        test.same decrypted.name, "alice_and_bobby.txt"
        test.same decrypted.senderID, Alice.miniLockID
        test.same decrypted.recipientID, Bobby.miniLockID
        test.end()
