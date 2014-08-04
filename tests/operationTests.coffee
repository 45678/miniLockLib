Alice = window.testFixtures.Alice
Bobby = window.testFixtures.Bobby

T = window.operationTests = {}

T["Encrypt private file for Alice"] = (test) ->
  readFileFixture "basic.txt", (error, buffer) ->
    return test.done(error) if error
    miniLockLib.encrypt
      file: buffer
      name: "alice.txt"
      keys: Alice.keys
      miniLockIDs: [Alice.miniLockID]
      callback: (error, encrypted) ->
        test.same Object.keys(encrypted), [
          "name"
          "data"
          "senderID"
        ]
        test.same encrypted.name, "alice.txt.minilock"
        test.ok encrypted.data
        test.same encrypted.data.size, 962
        test.same encrypted.data.type, "application/minilock"
        test.same encrypted.senderID, Alice.miniLockID
        test.done error

T["Encrypt file for Alice & Bobby"] = (test) ->
  readFileFixture "basic.txt", (error, buffer) ->
    return test.done(error) if error
    miniLockLib.encrypt
      file: buffer
      name: "alice_and_bobby.txt"
      keys: Alice.keys
      miniLockIDs: [
        Alice.miniLockID
        Bobby.miniLockID
      ]
      callback: (error, encrypted) ->
        test.same Object.keys(encrypted), [
          "name"
          "data"
          "senderID"
        ]
        test.same encrypted.name, "alice_and_bobby.txt.minilock"
        test.ok encrypted.data
        test.same encrypted.data.size, 1508
        test.same encrypted.data.type, "application/minilock"
        test.same encrypted.senderID, Alice.miniLockID
        test.done error

T["Alice can decrypt file her private file"] = (test) ->
  readFileFixture "alice.txt.minilock", (error, buffer) ->
    return test.done(error)  if error
    miniLockLib.decrypt
      file: buffer
      keys: Alice.keys
      callback: (error, decrypted) ->
        test.ok decrypted
        test.same Object.keys(decrypted), [
          "name"
          "data"
          "senderID"
        ]
        test.same decrypted.name, "basic.txt"
        test.ok decrypted.data, ""
        test.same decrypted.data.size, 20
        test.same decrypted.senderID, Alice.miniLockID
        test.done error

T["Alice can decrypt file for Alice & Bobby"] = (test) ->
  readFileFixture "alice_and_bobby.txt.minilock", (error, buffer) ->
    return test.done(error)  if error
    miniLockLib.decrypt
      file: buffer
      keys: Alice.keys
      callback: (error, decrypted) ->
        test.ok decrypted
        test.same Object.keys(decrypted), [
          "name"
          "data"
          "senderID"
        ]
        test.same decrypted.name, "basic.txt"
        test.ok decrypted.data, ""
        test.same decrypted.data.size, 20
        test.same decrypted.senderID, Alice.miniLockID
        test.done error

T["Bobby can decrypt file for Alice & Bobby"] = (test) ->
  readFileFixture "alice_and_bobby.txt.minilock", (error, buffer) ->
    return test.done(error)  if error
    miniLockLib.decrypt
      file: buffer
      keys: Bobby.keys
      callback: (error, decrypted) ->
        test.ok decrypted
        test.same Object.keys(decrypted), [
          "name"
          "data"
          "senderID"
        ]
        test.same decrypted.name, "basic.txt"
        test.ok decrypted.data, ""
        test.same decrypted.data.size, 20
        test.same decrypted.senderID, Alice.miniLockID
        test.done error

T["Bobby can’t decrypt Alices’s private file"] = (test) ->
  readFileFixture "alice.txt.minilock", (error, buffer) ->
    return test.done(error)  if error
    miniLockLib.decrypt
      file: buffer
      keys: Bobby.keys
      callback: (error, decrypted) ->
        test.same error, "File is not encrypted for this recipient"
        test.same decrypted, `undefined`
        test.done()

readFileFixture = (name, callback) ->
  request = new XMLHttpRequest
  request.open "GET", "/tests/_fixtures/" + name, true
  request.responseType = "blob"
  request.onreadystatechange = (event) ->
    if request.readyState is 4
      request.response.name = name
      readFileAsArrayBuffer request.response, callback
  request.send()

readFileAsArrayBuffer = (file, callback) ->
  reader = new FileReader()
  reader.onload = (readerEvent) ->
    callback `undefined`,
      name: file.name
      size: file.size
      data: readerEvent.target.result # (ArrayBuffer)
  reader.onerror = callback
  reader.readAsArrayBuffer file

# Paste the follwoing into a test to download a file after an operation.
# document.body.innerHTML += '<a id="download_file">Download</a>'
# var a = document.getElementById('download_file')
# a.setAttribute('download', encrypted.name)
# a.setAttribute('href', window.URL.createObjectURL(encrypted.data))
