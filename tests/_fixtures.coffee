window.testCases = []
window.testFixtures = {}

Alice = window.testFixtures.Alice = {}
Alice.secretPhrase = 'lions and tigers are not the only ones i am worried about'
Alice.emailAddress = 'alice@example.com'
Alice.miniLockID   = 'CeF5fM7SEdphjktdUbAXaMGm13m6mTZtbprtghvsMRYgw'
Alice.publicKey    = Base58.decode('3dz7VdGxZYTDQHHgXij2wgV3GRBu4GzJ8SLuwmAVB4kR')
Alice.secretKey    = Base58.decode('DsMtZntcp7riiWy9ng1xZ29tMPZQ9ioHNzk2i1UyChkF')
Alice.keys         = {publicKey: Alice.publicKey, secretKey: Alice.secretKey}

Bobby = window.testFixtures.Bobby = {}
Bobby.secretPhrase = 'No I also got a quesadilla, it’s from the value menu'
Bobby.emailAddress = 'bobby@example.com'
Bobby.miniLockID   = '2CtUp8U3iGykxaqyEDkGJjgZTsEtzzYQCd8NVmLspM4i2b'
Bobby.publicKey    = Base58.decode('GqNFkqGZv1dExFGTZLmhiqqbBUcoDarD9e1nwTFgj9zn')
Bobby.secretKey    = Base58.decode('A699ac6jesP643rkM71jAxs33wY9mk6VoYDQrG9B3Kw7')
Bobby.keys         = {publicKey: Bobby.publicKey, secretKey: Bobby.secretKey}

read = window.testFixtures.read = (name, callback) ->
  read.files[name] (error, processed) -> 
    if error then throw error
    callback(processed.data)

read.files = 
  "basic.txt": (callback) ->
    callback undefined,
      data: new Blob ["This is only a test!"], type: "text/plain"
      name: "basic.txt"
  "alice.txt.minilock": (callback) ->
    miniLockLib.encrypt
      data: new Blob ["This is only a test!"], type: "text/plain"
      name: "alice.txt"
      keys: Alice.keys
      miniLockIDs: [Alice.miniLockID]
      callback: callback
  "alice_and_bobby.txt.minilock": (callback) ->
    miniLockLib.encrypt
      data: new Blob ["This is only a test!"], type: "text/plain"
      name: "alice_and_bobby.txt"
      keys: Alice.keys
      miniLockIDs: [Alice.miniLockID, Bobby.miniLockID]
      callback: callback

readFromNetwork = window.testFixtures.readFromNetwork = (name, callback) ->
  request = new XMLHttpRequest
  request.open "GET", "/tests/_fixtures/" + name, true
  request.responseType = "blob"
  request.onreadystatechange = (event) ->
    if request.readyState is 4
      callback request.response
  request.send()

