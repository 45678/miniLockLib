tape = require "./tape_test_harness"
{Alice, Bobby, read, readFromNetwork} = require "./fixtures"

tape "Keys", (test) -> test.end()

tape "Mmke a pair of keys for Alice", (test) ->
  miniLockLib.makeKeyPair Alice.secretPhrase, Alice.emailAddress, (keys) ->
    test.ok Object.keys(keys).length is 2
    test.same keys.publicKey, Alice.publicKey
    test.same keys.secretKey, Alice.secretKey
    test.end()

tape "make a pair of keys for Bobby", (test) ->
  miniLockLib.makeKeyPair Bobby.secretPhrase, Bobby.emailAddress, (keys) ->
    test.ok Object.keys(keys).length is 2
    test.same keys.publicKey, Bobby.publicKey
    test.same keys.secretKey, Bobby.secretKey
    test.end()
