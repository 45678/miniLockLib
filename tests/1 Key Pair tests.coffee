{Alice, Bobby, read, readFromNetwork, tape} = require "./_fixtures"

tape "Key Pair", (test) -> test.end()

tape "Compute Alice’s keys from her secret phrase and email address", (test) ->
  miniLockLib.getKeyPair Alice.secretPhrase, Alice.emailAddress, (keys) ->
    test.ok Object.keys(keys).length is 2
    test.same keys.publicKey, Alice.publicKey
    test.same keys.secretKey, Alice.secretKey
    test.end()

tape "Compute Bobby’s keys from his secret phrase and email address", (test) ->
  miniLockLib.getKeyPair Bobby.secretPhrase, Bobby.emailAddress, (keys) ->
    test.ok Object.keys(keys).length is 2
    test.same keys.publicKey, Bobby.publicKey
    test.same keys.secretKey, Bobby.secretKey
    test.end()
