tape = require "./tape_test_harness"
{Alice, Bobby} = require "./fixtures"

tape "Acceptability", (test) -> test.end()

tape "Alice’s secret phrase is acceptable", (test) ->
  test.ok miniLockLib.Keys.secretPhraseIsAcceptable(Alice.secretPhrase)
  test.end()

tape "Bobby’s secret phrase is acceptable", (test) ->
  test.ok miniLockLib.Keys.secretPhraseIsAcceptable(Bobby.secretPhrase)
  test.end()

tape "Undefined secret phrase is unacceptable", (test) ->
  test.same miniLockLib.Keys.secretPhraseIsAcceptable(undefined), false
  test.end()

tape "Empty secret phrase is unacceptable", (test) ->
  test.same miniLockLib.Keys.secretPhraseIsAcceptable(""), false
  test.end()

tape "Blank secret phrase is unacceptable", (test) ->
  test.same miniLockLib.Keys.secretPhraseIsAcceptable("  "), false
  test.end()

tape "Short secret phrase is unacceptable", (test) ->
  test.same miniLockLib.Keys.secretPhraseIsAcceptable("My password is password"), false
  test.end()

tape "Alice’s email address is acceptable", (test) ->
  test.ok miniLockLib.Keys.emailAddressIsAcceptable(Alice.emailAddress)
  test.end()

tape "Bobby’s email address is acceptable", (test) ->
  test.ok miniLockLib.Keys.emailAddressIsAcceptable(Bobby.emailAddress)
  test.end()

tape "Empty email address is unacceptable", (test) ->
  test.same miniLockLib.Keys.emailAddressIsAcceptable(""), false
  test.end()

tape "Blank email address is unacceptable", (test) ->
  test.same miniLockLib.Keys.emailAddressIsAcceptable("  "), false
  test.end()

tape "Undefined email address is unacceptable", (test) ->
  test.same miniLockLib.Keys.emailAddressIsAcceptable(undefined), false
  test.end()
