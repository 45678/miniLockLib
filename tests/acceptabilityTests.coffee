window.testCases.push(T={})

{Alice, Bobby} = window.testFixtures

T["Alice’s secret phrase is acceptable"] = (test) ->
  test.ok miniLockLib.secretPhraseIsAcceptable(Alice.secretPhrase)
  test.done()

T["Bobby’s secret phrase is acceptable"] = (test) ->
  test.ok miniLockLib.secretPhraseIsAcceptable(Bobby.secretPhrase)
  test.done()

T["Undefined secret phrase is unacceptable"] = (test) ->
  test.same miniLockLib.secretPhraseIsAcceptable(`undefined`), false
  test.done()

T["Empty secret phrase is unacceptable"] = (test) ->
  test.same miniLockLib.secretPhraseIsAcceptable(""), false
  test.done()

T["Blank secret phrase is unacceptable"] = (test) ->
  test.same miniLockLib.secretPhraseIsAcceptable("  "), false
  test.done()

T["Short secret phrase is unacceptable"] = (test) ->
  test.same miniLockLib.secretPhraseIsAcceptable("My password is password"), false
  test.done()

T["Alice’s email address is acceptable"] = (test) ->
  test.ok miniLockLib.emailAddressIsAcceptable(Alice.emailAddress)
  test.done()

T["Bobby’s email address is acceptable"] = (test) ->
  test.ok miniLockLib.emailAddressIsAcceptable(Bobby.emailAddress)
  test.done()

T["Empty email address is unacceptable"] = (test) ->
  test.same miniLockLib.emailAddressIsAcceptable(""), false
  test.done()

T["Blank email address is unacceptable"] = (test) ->
  test.same miniLockLib.emailAddressIsAcceptable("  "), false
  test.done()

T["Undefined email address is unacceptable"] = (test) ->
  test.same miniLockLib.emailAddressIsAcceptable(`undefined`), false
  test.done()
