tape = require "./tape_test_harness"
{Alice, Bobby, read} = require "./fixtures"

tape "A demo of miniLockLib.encrypt & miniLockLib.decrypt", (test) -> test.end()

tape "Encrypt a file for Alice", (test) ->
  read "basic.txt", (blob) ->
    miniLockLib.encrypt
      data: blob
      name: "alice.txt"
      keys: Alice.keys
      miniLockIDs: [Alice.miniLockID]
      callback: (error, encrypted) ->
        if error? then return test.end(error)
        test.ok encrypted.name is "alice.txt.minilock"
        test.ok encrypted.data.size is 962
        test.ok encrypted.data.type is "application/minilock"
        test.ok encrypted.senderID is Alice.miniLockID
        test.end()
        # a = document.getElementById("link_to_download")
        # a.setAttribute("href", window.URL.createObjectURL(encrypted.data))
        # a.setAttribute("download", encrypted.name)
        # a.innerHTML = "Download: "+encrypted.name

tape "Alice can decrypt file that was encrypted for her", (test) ->
  read "alice.txt.minilock", (blob) ->
    miniLockLib.decrypt
      data: blob
      keys: Alice.keys
      callback: (error, decrypted) ->
        if error then return test.end(error)
        test.ok decrypted.data.size is 20
        test.ok decrypted.name is "alice.txt"
        test.ok decrypted.senderID is Alice.miniLockID
        test.ok decrypted.recipientID is Alice.miniLockID
        test.end()

tape "Bobby can’t decrypt file that was only encrypted for Alice", (test) ->
  read "alice.txt.minilock", (blob) ->
    miniLockLib.decrypt
      data: blob
      keys: Bobby.keys
      callback: (error, decrypted) ->
        test.equal "File is not encrypted for this recipient", error
        test.equal undefined, decrypted
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
        # a = document.getElementById("link_to_download")
        # a.setAttribute("href", window.URL.createObjectURL(encrypted.data))
        # a.setAttribute("download", encrypted.name)
        # a.innerHTML = "Download: "+encrypted.name

tape "Alice can decrypt file that was encrypted for Alice & Bobby", (test) ->
  read "alice_and_bobby.txt.minilock", (blob) ->
    miniLockLib.decrypt
      data: blob
      keys: Alice.keys
      callback: (error, decrypted) ->
        if error then return test.end(error)
        test.ok decrypted.data.size is 20
        test.ok decrypted.name is "alice_and_bobby.txt"
        test.ok decrypted.senderID is Alice.miniLockID
        test.ok decrypted.recipientID is Alice.miniLockID
        test.end()

tape "Bobby can decrypt file that was encrypted for Alice & Bobby", (test) ->
  read "alice_and_bobby.txt.minilock", (blob) ->
    miniLockLib.decrypt
      data: blob
      keys: Bobby.keys
      callback: (error, decrypted) ->
        if error then return test.end(error)
        test.ok decrypted.data.size is 20
        test.ok decrypted.name is "alice_and_bobby.txt"
        test.ok decrypted.senderID is Alice.miniLockID
        test.ok decrypted.recipientID is Bobby.miniLockID
        test.end()
