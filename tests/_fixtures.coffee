Alice = exports.Alice = {}
Alice.secretPhrase = "lions and tigers are not the only ones i am worried about"
Alice.emailAddress = "alice@example.com"
Alice.miniLockID   = "CeF5fM7SEdphjktdUbAXaMGm13m6mTZtbprtghvsMRYgw"
Alice.publicKey    = Base58.decode("3dz7VdGxZYTDQHHgXij2wgV3GRBu4GzJ8SLuwmAVB4kR")
Alice.secretKey    = Base58.decode("DsMtZntcp7riiWy9ng1xZ29tMPZQ9ioHNzk2i1UyChkF")
Alice.keys         = {publicKey: Alice.publicKey, secretKey: Alice.secretKey}

Bobby = exports.Bobby = {}
Bobby.secretPhrase = "No I also got a quesadilla, it’s from the value menu"
Bobby.emailAddress = "bobby@example.com"
Bobby.miniLockID   = "2CtUp8U3iGykxaqyEDkGJjgZTsEtzzYQCd8NVmLspM4i2b"
Bobby.publicKey    = Base58.decode("GqNFkqGZv1dExFGTZLmhiqqbBUcoDarD9e1nwTFgj9zn")
Bobby.secretKey    = Base58.decode("A699ac6jesP643rkM71jAxs33wY9mk6VoYDQrG9B3Kw7")
Bobby.keys         = {publicKey: Bobby.publicKey, secretKey: Bobby.secretKey}

read = exports.read = (name, callback) ->
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

readFromNetwork = exports.readFromNetwork = (name, callback) ->
  request = new XMLHttpRequest
  request.open "GET", "/tests/_fixtures/" + name, true
  request.responseType = "blob"
  request.onreadystatechange = (event) ->
    if request.readyState is 4
      callback request.response
  request.send()

exports.tape = require("tape").createHarness()
testKit = 
testTemplate = document.getElementById("test_template")
failureTemplate = document.getElementById("failure_template")
assertionTemplate = document.getElementById("assertion_template")
idOfCurrentlyRunningTest = undefined
untouched = true
failedTests = []

window.onmousewheel = ->
  window.onmousewheel = undefined
  untouched = false

exports.tape.createStream(objectMode:yes).on "data", (data) ->
  switch 
    when data.type is "test"
      idOfCurrentlyRunningTest = data.id
      element = testTemplate.cloneNode(true)
      element.id = "test_#{data.id}"
      element.querySelector(".name").innerText = data.name
      element.className += " started"
      document.body.appendChild(element)
      element.scrollIntoView() if untouched
      element.startedAt = Date.now()
      element.querySelector("div.id").innerText = (data.id / 1000).toFixed(3).replace("0.", "#")
      document.body.className = "running"
    when data.id?
      element = document.getElementById("test_#{idOfCurrentlyRunningTest}")
      className = if data.ok then "ok" else "failed"
      element.className = element.className.replace(className,"").trim() + " " + className
      assertionEl = assertionTemplate.cloneNode(true)
      assertionEl.id = "test_#{idOfCurrentlyRunningTest}_assertion_#{data.id}"
      element.querySelector('.assertions').appendChild(assertionEl)
      if data.ok isnt true
        failedTests.push(data.id) unless data.id in failedTests
        document.getElementById("number_of_failed_tests").innerText = failedTests.length
        failureEl = failureTemplate.cloneNode("true")
        failureEl.id = ""
        failureEl.querySelector("pre.expected").innerText += data.expected
        failureEl.querySelector("pre.received").innerText += data.actual
        failureEl.querySelector("pre.at").innerText = data.at
        failureEl.querySelector("pre.error_stack").innerText = data.error.stack
        element.appendChild(failureEl)
    when data.type is "end"
      idOfCurrentlyRunningTest = undefined
      element = document.getElementById("test_#{data.test}")
      element.className = element.className.replace("started", "ended")
      element.querySelector("div.duration").innerText = "#{((Date.now() - element.startedAt) / 1000).toFixed(2)}s"
      document.getElementById("number_of_tests").innerText = data.test
  if idOfCurrentlyRunningTest is undefined
    document.body.className = "stopped"

