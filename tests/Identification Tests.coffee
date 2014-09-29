tape = require "./tape_test_harness"
{Alice, Bobby, read, readFromNetwork} = require "./fixtures"

tape "Identification", (test) -> test.end()

tape "Decode public key from Alice’s ID", (test) ->
  publicKey = miniLockLib.ID.decode(Alice.miniLockID)
  test.same publicKey, Alice.publicKey
  test.end()

tape "Decode public key from Bobby’s ID", (test) ->
  publicKey = miniLockLib.ID.decode(Bobby.miniLockID)
  test.same publicKey, Bobby.publicKey
  test.end()

tape "Make ID for Alice’s public key", (test) ->
  miniLockID = miniLockLib.ID.encode(Alice.publicKey)
  test.same miniLockID, Alice.miniLockID
  test.end()

tape "Make ID for Bobby’s public key", (test) ->
  miniLockID = miniLockLib.ID.encode(Alice.publicKey)
  test.same miniLockID, Alice.miniLockID
  test.end()

tape "Can’t make ID for undefined key", (test) ->
  miniLockID = miniLockLib.ID.encode(`undefined`)
  test.same miniLockID, `undefined`
  test.end()

tape "Can’t make ID for key that is too short", (test) ->
  miniLockID = miniLockLib.ID.encode(new Uint8Array(16))
  test.same miniLockID, `undefined`
  test.end()

tape "Can’t make ID for key that is too long", (test) ->
  miniLockID = miniLockLib.ID.encode(new Uint8Array(64))
  test.same miniLockID, `undefined`
  test.end()
