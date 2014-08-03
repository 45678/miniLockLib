new(function(){

var Alice = window.testFixtures.Alice
var Bobby = window.testFixtures.Bobby

var T = window.keyPairTests = this

T['Compute Alice’s keys from her secret phrase and email address'] = function(test) {
  miniLockLib.getKeyPair(Alice.secretPhrase, Alice.emailAddress, function(keys){
    test.same(Object.keys(keys), ['publicKey', 'secretKey'])
    test.same(keys.publicKey, Alice.publicKey)
    test.same(keys.secretKey, Alice.secretKey)
    test.done()
  })
}

T['Compute Bobby’s keys from his secret phrase and email address'] = function(test) {
  miniLockLib.getKeyPair(Bobby.secretPhrase, Bobby.emailAddress, function(keys){
    test.same(Object.keys(keys), ['publicKey', 'secretKey'])
    test.same(keys.publicKey, Bobby.publicKey)
    test.same(keys.secretKey, Bobby.secretKey)
    test.done()
  })
}

}) // End of top-level function body.
