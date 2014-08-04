Alice = window.testFixtures.Alice
Bobby = window.testFixtures.Bobby

T = window.keyPairTests = {}

T["Compute Alice’s keys from her secret phrase and email address"] = (test) ->
  miniLockLib.getKeyPair Alice.secretPhrase, Alice.emailAddress, (keys) ->
    test.same Object.keys(keys), [
      "publicKey"
      "secretKey"
    ]
    test.same keys.publicKey, Alice.publicKey
    test.same keys.secretKey, Alice.secretKey
    test.done()

T["Compute Bobby’s keys from his secret phrase and email address"] = (test) ->
  miniLockLib.getKeyPair Bobby.secretPhrase, Bobby.emailAddress, (keys) ->
    test.same Object.keys(keys), [
      "publicKey"
      "secretKey"
    ]
    test.same keys.publicKey, Bobby.publicKey
    test.same keys.secretKey, Bobby.secretKey
    test.done()
