{Alice, Bobby, tape} = require "./_fixtures"

tape "Acceptability Tests", (test) -> test.end()

tape "Alice’s secret phrase is acceptable", (test) ->
  test.ok miniLockLib.secretPhraseIsAcceptable(Alice.secretPhrase)
  test.end()

tape "Bobby’s secret phrase is acceptable", (test) ->
  test.ok miniLockLib.secretPhraseIsAcceptable(Bobby.secretPhrase)
  test.end()

tape "Undefined secret phrase is unacceptable", (test) ->
  test.same miniLockLib.secretPhraseIsAcceptable(undefined), false
  test.end()

tape "Empty secret phrase is unacceptable", (test) ->
  test.same miniLockLib.secretPhraseIsAcceptable(""), false
  test.end()

tape "Blank secret phrase is unacceptable", (test) ->
  test.same miniLockLib.secretPhraseIsAcceptable("  "), false
  test.end()

tape "Short secret phrase is unacceptable", (test) ->
  test.same miniLockLib.secretPhraseIsAcceptable("My password is password"), false
  test.end()

tape "Alice’s email address is acceptable", (test) ->
  test.ok miniLockLib.emailAddressIsAcceptable(Alice.emailAddress)
  test.end()

tape "Bobby’s email address is acceptable", (test) ->
  test.ok miniLockLib.emailAddressIsAcceptable(Bobby.emailAddress)
  test.end()

tape "Empty email address is unacceptable", (test) ->
  test.same miniLockLib.emailAddressIsAcceptable(""), false
  test.end()

tape "Blank email address is unacceptable", (test) ->
  test.same miniLockLib.emailAddressIsAcceptable("  "), false
  test.end()

tape "Undefined email address is unacceptable", (test) ->
  test.same miniLockLib.emailAddressIsAcceptable(undefined), false
  test.end()

