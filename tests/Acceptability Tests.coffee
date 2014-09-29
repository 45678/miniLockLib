tape = require "./tape_test_harness"
{Alice, Bobby} = require "./fixtures"

tape "Acceptability", (test) -> test.end()

tape "Alice’s secret phrase is acceptable", (test) ->
  test.ok miniLockLib.SecretPhrase.isAcceptable(Alice.secretPhrase)
  test.end()

tape "Bobby’s secret phrase is acceptable", (test) ->
  test.ok miniLockLib.SecretPhrase.isAcceptable(Bobby.secretPhrase)
  test.end()

tape "Undefined secret phrase is unacceptable", (test) ->
  test.same miniLockLib.SecretPhrase.isAcceptable(undefined), false
  test.end()

tape "Empty secret phrase is unacceptable", (test) ->
  test.same miniLockLib.SecretPhrase.isAcceptable(""), false
  test.end()

tape "Blank secret phrase is unacceptable", (test) ->
  test.same miniLockLib.SecretPhrase.isAcceptable("  "), false
  test.end()

tape "Short secret phrase is unacceptable", (test) ->
  test.same miniLockLib.SecretPhrase.isAcceptable("My password is password"), false
  test.end()

tape "Alice’s email address is acceptable", (test) ->
  test.ok miniLockLib.EmailAddress.isAcceptable(Alice.emailAddress)
  test.end()

tape "Bobby’s email address is acceptable", (test) ->
  test.ok miniLockLib.EmailAddress.isAcceptable(Bobby.emailAddress)
  test.end()

tape "Empty email address is unacceptable", (test) ->
  test.same miniLockLib.EmailAddress.isAcceptable(""), false
  test.end()

tape "Blank email address is unacceptable", (test) ->
  test.same miniLockLib.EmailAddress.isAcceptable("  "), false
  test.end()

tape "Undefined email address is unacceptable", (test) ->
  test.same miniLockLib.EmailAddress.isAcceptable(undefined), false
  test.end()

tape "Alice’s ID is acceptable", (test) ->
  test.same miniLockLib.ID.isAcceptable(Alice.miniLockID), true
  test.end()

tape "Bobby’s ID is acceptable", (test) ->
  test.same miniLockLib.ID.isAcceptable(Alice.miniLockID), true
  test.end()

tape "Undefined ID is unacceptable", (test) ->
  test.same miniLockLib.ID.isAcceptable(`undefined`), false
  test.end()

tape "Blank ID is unacceptable", (test) ->
  test.same miniLockLib.ID.isAcceptable(""), false
  test.same miniLockLib.ID.isAcceptable(" "), false
  test.same miniLockLib.ID.isAcceptable("  "), false
  test.end()

tape "Truncated ID is unacceptable", (test) ->
  test.same miniLockLib.ID.isAcceptable(Alice.miniLockID.slice(0, -1)), false
  test.same miniLockLib.ID.isAcceptable(Alice.miniLockID.slice(1)), false
  test.end()

tape "ID with extra characters is unacceptable", (test) ->
  test.same miniLockLib.ID.isAcceptable(Alice.miniLockID + "A"), false
  test.same miniLockLib.ID.isAcceptable("A" + Alice.miniLockID), false
  test.end()
