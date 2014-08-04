Alice = window.testFixtures.Alice
Bobby = window.testFixtures.Bobby
readFileAsBlob = window.testFixtures.readFileAsBlob

T = window.operationTests = {}

T["Encrypt file for Alice"] = (test) ->
  readFileAsBlob "basic.txt", (error, blob) ->
    if error? then return test.done(error) 
    miniLockLib.encrypt
      data: blob
      name: "alice.txt"
      keys: Alice.keys
      miniLockIDs: [Alice.miniLockID]
      callback: (error, encrypted) ->
        if error? then return test.done(error)
        test.same encrypted.name, "alice.txt.minilock"
        test.same encrypted.data.size, 962
        test.same encrypted.data.type, "application/minilock"
        test.same encrypted.senderID, Alice.miniLockID
        test.done()
        # a = document.getElementById('link_to_download')
        # a.setAttribute('href', window.URL.createObjectURL(encrypted.data))
        # a.setAttribute('download', 'alice.txt.minilock')
        # a.innerHTML = 'Download: '+'alice.txt.minilock'

T["Encrypt file for Alice & Bobby"] = (test) ->
  readFileAsBlob "basic.txt", (error, blob) ->
    if error? then return test.done(error) 
    miniLockLib.encrypt
      data: blob
      name: "alice_and_bobby.txt"
      keys: Alice.keys
      miniLockIDs: [Alice.miniLockID, Bobby.miniLockID]
      callback: (error, encrypted) ->
        if error? then return test.done(error) 
        test.same encrypted.name, "alice_and_bobby.txt.minilock"
        test.same encrypted.data.size, 1508
        test.same encrypted.data.type, "application/minilock"
        test.same encrypted.senderID, Alice.miniLockID
        test.done()
        # a = document.getElementById('link_to_download')
        # a.setAttribute('href', window.URL.createObjectURL(encrypted.data))
        # a.setAttribute('download', 'alice_and_bobby.txt.minilock')
        # a.innerHTML = 'Download: '+'alice_and_bobby.txt.minilock'


T["Alice can decrypt the file she encrypted with the miniLock App"] = (test) ->
  readFileAsBlob 'basic.txt.encrypted_with_minilock_app.minilock', (error, blob) ->
    if error then return test.done(error)
    miniLockLib.decrypt
      data: blob
      keys: Alice.keys
      callback: (error, decrypted) ->
        if error then return test.done(error)
        test.ok decrypted.data.size is 20
        test.ok decrypted.name is "basic.txt"
        test.ok decrypted.senderID is Alice.miniLockID
        test.ok decrypted.recipientID is Alice.miniLockID
        test.done()

T["Alice can decrypt the file she encrypted with miniLockLib"] = (test) ->
  readFileAsBlob 'basic.txt.encrypted_with_minilocklib.minilock', (error, blob) ->
    if error then return test.done(error)
    miniLockLib.decrypt
      data: blob
      keys: Alice.keys
      callback: (error, decrypted) ->
        if error then return test.done(error)
        test.ok decrypted.data.size is 20
        test.ok decrypted.name is "basic.txt"
        test.ok decrypted.senderID is Alice.miniLockID
        test.ok decrypted.recipientID is Alice.miniLockID
        test.done()

T["Alice can decrypt file encrypted for Alice"] = (test) ->
  readFileAsBlob "alice.txt.minilock", (error, blob) ->
    return test.done(error)  if error
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

T["Alice can decrypt file encrypted for Alice & Bobby"] = (test) ->
  readFileAsBlob "alice_and_bobby.txt.minilock", (error, blob) ->
    return test.done(error)  if error
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

T["Bobby can decrypt file encrypted for Alice & Bobby"] = (test) ->
  readFileAsBlob "alice_and_bobby.txt.minilock", (error, blob) ->
    if error then return test.done(error)
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

T["Bobby can’t decrypt file encrypted for Alices"] = (test) ->
  readFileAsBlob "basic.txt.encrypted_with_minilocklib.minilock", (error, blob) ->
    if error then return test.done(error)
    miniLockLib.decrypt
      data: blob
      keys: Bobby.keys
      callback: (error, decrypted) ->
        test.same error, "File is not encrypted for this recipient"
        test.same decrypted, `undefined`
        test.done()

