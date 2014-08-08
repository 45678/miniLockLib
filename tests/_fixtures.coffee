Alice = exports.Alice = {}
Alice.secretPhrase = "lions and tigers are not the only ones i am worried about"
Alice.emailAddress = "alice@example.com"
Alice.miniLockID   = "CeF5fM7SEdphjktdUbAXaMGm13m6mTZtbprtghvsMRYgw"
Alice.publicKey    = miniLockLib.Base58.decode("3dz7VdGxZYTDQHHgXij2wgV3GRBu4GzJ8SLuwmAVB4kR")
Alice.secretKey    = miniLockLib.Base58.decode("DsMtZntcp7riiWy9ng1xZ29tMPZQ9ioHNzk2i1UyChkF")
Alice.keys         = {publicKey: Alice.publicKey, secretKey: Alice.secretKey}

Bobby = exports.Bobby = {}
Bobby.secretPhrase = "No I also got a quesadilla, it’s from the value menu"
Bobby.emailAddress = "bobby@example.com"
Bobby.miniLockID   = "2CtUp8U3iGykxaqyEDkGJjgZTsEtzzYQCd8NVmLspM4i2b"
Bobby.publicKey    = miniLockLib.Base58.decode("GqNFkqGZv1dExFGTZLmhiqqbBUcoDarD9e1nwTFgj9zn")
Bobby.secretKey    = miniLockLib.Base58.decode("A699ac6jesP643rkM71jAxs33wY9mk6VoYDQrG9B3Kw7")
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
      'callback': callback
  "alice_and_bobby.txt.minilock": (callback) ->
    miniLockLib.encrypt
      data: new Blob ["This is only a test!"], type: "text/plain"
      name: "alice_and_bobby.txt"
      keys: Alice.keys
      miniLockIDs: [Alice.miniLockID, Bobby.miniLockID]
      'callback': callback

readFromNetwork = exports.readFromNetwork = (name, callback) ->
  request = new XMLHttpRequest
  request.open "GET", "/tests/_fixtures/" + name, true
  request.responseType = "blob"
  request.onreadystatechange = (event) ->
    if request.readyState is 4
      callback request.response
  request.send()

exports.tape = window.tape.createHarness()
testTemplate = document.getElementById("test_template")
failureTemplate = document.getElementById("failure_template")
assertionTemplate = document.getElementById("assertion_template")
numberOfTests = document.getElementById("number_of_tests")
numberOfFailedTests = document.getElementById("number_of_failed_tests")
body = document.body
idOfCurrentlyRunningTest = undefined
untouched = true
failedTests = []

window.onmousewheel = ->
  window.onmousewheel = undefined
  untouched = false

delay = (amount, callback) -> setTimeout(callback, amount)

exports.tape.createStream(objectMode:yes).on "data", (data) ->
  switch
    when data.type is "test"
      idOfCurrentlyRunningTest = data.id
      insertTestElement(data)
      renderBodyElement(data)
    when data.operator?
      fixBrokenThrowsOperatorData(data)
      if data.ok is false
        failedTests.push(idOfCurrentlyRunningTest) unless idOfCurrentlyRunningTest in failedTests
      element = findElementForTest(idOfCurrentlyRunningTest)
      renderTestElementUpdate(element, data)
      insertTestAssertion(element, data)
      insertFailure(element, data) unless data.ok
    when data.type is "end"
      idOfCurrentlyRunningTest = undefined
      renderTestElementEnded(findElementForTest(data.test), data)
      numberOfFailedTests.innerText = failedTests.length if failedTests.length isnt 0
      numberOfTests.innerText = data.test
      renderBodyElement(data)
    else
      console.info("Unhandled", data)

renderBodyElement = (data) ->
  body.className = body.className.replace("undefined", "")
  body.className = switch
    when data.type is "test"
      body.className.replace("stopped", "running")
    when data.type is "end"
      body.className.replace("running", "stopped")
    else
      body.className
  if failedTests.length is 1 and body.className.indexOf("fail") is -1
    body.className += " failures"

insertTestElement = (data) ->
  element = testTemplate.cloneNode(true)
  element.id = "test_#{data.id}"
  element.querySelector(".name").innerText = data.name
  element.className += " started"
  document.body.appendChild(element)
  element.scrollIntoView() if untouched
  element.startedAt = Date.now()
  element.querySelector("div.id").innerText = (data.id / 1000).toFixed(3).replace("0.", "#")

renderTestElementUpdate = (element, data) ->
  className = if data.ok then "ok" else "failed"
  element.className = element.className.replace(className,"").trim() + " " + className

renderTestElementEnded = (element, data) ->
  element.className = element.className.replace("started", "ended")
  element.querySelector("div.duration").innerText = "#{((Date.now() - element.startedAt) / 1000).toFixed(2)}s"

insertTestAssertion = (element, data) ->
  assertionEl = assertionTemplate.cloneNode(true)
  assertionEl.id = "test_#{idOfCurrentlyRunningTest}_assertion_#{data.id}"
  element.className = element.className.replace('empty', '').trim()
  element.querySelector('.assertions').appendChild(assertionEl)

insertFailure = (element, data) ->
  failureEl = failureTemplate.cloneNode("true")
  failureEl.id = ""
  if typeof data.expected is "function"
    failureEl.querySelector("pre.expected").innerHTML += data.expected
  else
    failureEl.querySelector("pre.expected").innerHTML += JSON.stringify(data.expected, undefined, "  ")
  if typeof data.actual is "function"
    failureEl.querySelector("pre.received").innerHTML += data.actual
  else
    failureEl.querySelector("pre.received").innerHTML += JSON.stringify(data.actual, undefined, "  ")
  if data.error?
    failureEl.querySelector("pre.error_stack").innerText = data.error.stack
  element.appendChild(failureEl)
  if failedTests.length is 1
    if untouched is true
      delay 1, -> 
        untouched = false
        element.scrollIntoView(true)

fixBrokenThrowsOperatorData = (data) ->
  if (data.operator is "throws") and (data.name isnt data.actual)
    data.ok = no
    data.expected = data.name
    data.name = undefined
    data.fixedForThrowsOperator = yes

findElementForTest = (id) ->
  document.getElementById("test_#{id}")




