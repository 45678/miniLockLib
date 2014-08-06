window.testCases.push(T={})

{Alice, Bobby} = window.testFixtures

T["Alice’s ID is acceptable"] = (test) ->
  test.same miniLockLib.ID.isAcceptable(Alice.miniLockID), true
  test.done()

T["Bobby’s ID is acceptable"] = (test) ->
  test.same miniLockLib.ID.isAcceptable(Alice.miniLockID), true
  test.done()

T["Undefined ID is unacceptable"] = (test) ->
  test.same miniLockLib.ID.isAcceptable(`undefined`), false
  test.done()

T["Blank ID is unacceptable"] = (test) ->
  test.same miniLockLib.ID.isAcceptable(""), false
  test.same miniLockLib.ID.isAcceptable(" "), false
  test.same miniLockLib.ID.isAcceptable("  "), false
  test.done()

T["Truncated ID is unacceptable"] = (test) ->
  test.same miniLockLib.ID.isAcceptable(Alice.miniLockID.slice(0, -1)), false
  test.same miniLockLib.ID.isAcceptable(Alice.miniLockID.slice(1)), false
  test.done()

T["ID with extra characters is unacceptable"] = (test) ->
  test.same miniLockLib.ID.isAcceptable(Alice.miniLockID + "A"), false
  test.same miniLockLib.ID.isAcceptable("A" + Alice.miniLockID), false
  test.done()

T["Decode public key from Alice’s ID"] = (test) ->
  publicKey = miniLockLib.ID.decode(Alice.miniLockID)
  test.same publicKey, Alice.publicKey
  test.done()

T["Decode public key from Bobby’s ID"] = (test) ->
  publicKey = miniLockLib.ID.decode(Bobby.miniLockID)
  test.same publicKey, Bobby.publicKey
  test.done()

T["Make ID for Alice’s public key"] = (test) ->
  miniLockID = miniLockLib.ID.encode(Alice.publicKey)
  test.same miniLockID, Alice.miniLockID
  test.done()

T["Make ID for Bobby’s public key"] = (test) ->
  miniLockID = miniLockLib.ID.encode(Alice.publicKey)
  test.same miniLockID, Alice.miniLockID
  test.done()

T["Can’t make ID for undefined key"] = (test) ->
  miniLockID = miniLockLib.ID.encode(`undefined`)
  test.same miniLockID, `undefined`
  test.done()

T["Can’t make ID for key that is too short"] = (test) ->
  miniLockID = miniLockLib.ID.encode(new Uint8Array(16))
  test.same miniLockID, `undefined`
  test.done()

T["Can’t make ID for key that is too long"] = (test) ->
  miniLockID = miniLockLib.ID.encode(new Uint8Array(64))
  test.same miniLockID, `undefined`
  test.done()
