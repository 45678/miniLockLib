new(function(){

var Alice = window.testFixtures.Alice
var Bobby = window.testFixtures.Bobby

var T = window.acceptabilityTests = this

T['Alice’s secret phrase is acceptable to miniLock'] = function(test) {
  test.ok(miniLockLib.secretPhraseIsAcceptable(Alice.secretPhrase))
  test.done()
}

T['Bobby’s secret phrase is acceptable to miniLock'] = function(test) {
  test.ok(miniLockLib.secretPhraseIsAcceptable(Bobby.secretPhrase))
  test.done()
}

T['Empty secret phrase is unacceptable'] = function(test) {
  test.same(miniLockLib.secretPhraseIsAcceptable(''), false)
  test.done()
}

T['Blank secret phrase is unacceptable'] = function(test) {
  test.same(miniLockLib.secretPhraseIsAcceptable('  '), false)
  test.done()
}

T['Short secret phrase is unacceptable'] = function(test) {
  test.same(miniLockLib.secretPhraseIsAcceptable('My password is password'), false)
  test.done()
}

T['Can’t determine acceptability of undefined secret phrase'] = function(test) {
  try {
    test.same(miniLockLib.secretPhraseIsAcceptable(undefined), false)
  }
  catch (error) {
    test.ok(error)
    test.done()
  }
}

}) // End of top-level function body.
