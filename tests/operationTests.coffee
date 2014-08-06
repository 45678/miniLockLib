window.testCases.push(T={})

{Alice, Bobby, read} = window.testFixtures

T["Encrypt a file for Alice"] = (test) ->
  read "basic.txt", (blob) ->
    miniLockLib.encrypt
      data: blob
      name: "alice.txt"
      keys: Alice.keys
      miniLockIDs: [Alice.miniLockID]
      callback: (error, encrypted) ->
        if error? then return test.done(error)
        test.ok encrypted.name is "alice.txt.minilock"
        test.ok encrypted.data.size is 962
        test.ok encrypted.data.type is "application/minilock"
        test.ok encrypted.senderID is Alice.miniLockID
        test.done()
        # a = document.getElementById("link_to_download")
        # a.setAttribute("href", window.URL.createObjectURL(encrypted.data))
        # a.setAttribute("download", encrypted.name)
        # a.innerHTML = "Download: "+encrypted.name

T["Alice can decrypt file that was encrypted for her"] = (test) ->
  read "alice.txt.minilock", (blob) ->
    miniLockLib.decrypt
      data: blob
      keys: Alice.keys
      callback: (error, decrypted) ->
        if error then return test.done(error)
        test.ok decrypted.data.size is 20
        test.ok decrypted.name is "alice.txt"
        test.ok decrypted.senderID is Alice.miniLockID
        test.ok decrypted.recipientID is Alice.miniLockID
        test.done()

T["Bobby can’t decrypt file that was only encrypted for Alice"] = (test) ->
  read "alice.txt.minilock", (blob) ->
    miniLockLib.decrypt
      data: blob
      keys: Bobby.keys
      callback: (error, decrypted) ->
        test.ok error is "File is not encrypted for this recipient"
        test.ok decrypted is undefined
        test.done()

T["Encrypt a file for Alice & Bobby"] = (test) ->
  read "basic.txt", (blob) ->
    miniLockLib.encrypt
      data: blob
      name: "alice_and_bobby.txt"
      keys: Alice.keys
      miniLockIDs: [Alice.miniLockID, Bobby.miniLockID]
      callback: (error, encrypted) ->
        if error? then return test.done(error)
        test.ok encrypted.name is "alice_and_bobby.txt.minilock"
        test.ok encrypted.data.size is 1508
        test.ok encrypted.data.type is "application/minilock"
        test.ok encrypted.senderID is Alice.miniLockID
        test.done()
        # a = document.getElementById("link_to_download")
        # a.setAttribute("href", window.URL.createObjectURL(encrypted.data))
        # a.setAttribute("download", encrypted.name)
        # a.innerHTML = "Download: "+encrypted.name

T["Alice can decrypt file that was encrypted for Alice & Bobby"] = (test) ->
  read "alice_and_bobby.txt.minilock", (blob) ->
    miniLockLib.decrypt
      data: blob
      keys: Alice.keys
      callback: (error, decrypted) ->
        if error then return test.done(error)
        test.ok decrypted.data.size is 20
        test.ok decrypted.name is "alice_and_bobby.txt"
        test.ok decrypted.senderID is Alice.miniLockID
        test.ok decrypted.recipientID is Alice.miniLockID
        test.done()

T["Bobby can decrypt file that was encrypted for Alice & Bobby"] = (test) ->
  read "alice_and_bobby.txt.minilock", (blob) ->
    miniLockLib.decrypt
      data: blob
      keys: Bobby.keys
      callback: (error, decrypted) ->
        if error then return test.done(error)
        test.ok decrypted.data.size is 20
        test.ok decrypted.name is "alice_and_bobby.txt"
        test.ok decrypted.senderID is Alice.miniLockID
        test.ok decrypted.recipientID is Bobby.miniLockID
        test.done()
