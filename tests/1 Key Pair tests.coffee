tape = require "./tape_test_harness"
{Alice, Bobby} = require "./fixtures"

tape "Keys", (test) -> test.end()

tape "make a pair of keys for Alice", (test) ->
  miniLockLib.makeKeyPair Alice.secretPhrase, Alice.emailAddress, (error, keys) ->
    test.ok Object.keys(keys).length is 2
    test.same keys.publicKey, Alice.publicKey
    test.same keys.secretKey, Alice.secretKey
    test.end()

tape "make a pair of keys for Bobby", (test) ->
  miniLockLib.makeKeyPair Bobby.secretPhrase, Bobby.emailAddress, (error, keys) ->
    test.ok Object.keys(keys).length is 2
    test.same keys.publicKey, Bobby.publicKey
    test.same keys.secretKey, Bobby.secretKey
    test.end()

tape "can’t make keys without a callback", (test) ->
  returned = miniLockLib.makeKeyPair()
  test.same returned, "Can’t make a pair of keys without a callback function."
  returned = miniLockLib.makeKeyPair(Bobby.secretPhrase, Bobby.emailAddress)
  test.same returned, "Can’t make a pair of keys without a callback function."
  test.end()

tape "can’t make keys without a secret phrase", (test) ->
  miniLockLib.makeKeyPair undefined, Bobby.emailAddress, (error) ->
    test.same error, "Can’t make a pair of keys without a secret phrase."
    test.end()

tape "can’t make keys without an email address", (test) ->
  miniLockLib.makeKeyPair Bobby.secretPhrase, undefined, (error) ->
    test.same error, "Can’t make a pair of keys without an email address."
    test.end()
