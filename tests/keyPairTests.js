new(function(){

var Alice = window.testFixtures.Alice
var Bobby = window.testFixtures.Bobby

var T = window.keyPairTests = this

T['Alice’s secret phrase is acceptable to miniLock'] = function(test) {
	test.ok(miniLockLib.secretPhraseIsAcceptable(Alice.secretPhrase))
	test.done()
}

T['Bobby’s secret phrase is acceptable to miniLock'] = function(test) {
	test.ok(miniLockLib.secretPhraseIsAcceptable(Bobby.secretPhrase))
	test.done()
}

T['Short secret phrase is unacceptable'] = function(test) {
	test.same(miniLockLib.secretPhraseIsAcceptable('My password is password'), false)
	test.done()
}

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

T['Make ID for Alice’s public key'] = function(test) {
	id = miniLockLib.makeID(Alice.publicKey)
	test.same(id, Alice.miniLockID)
	test.done()
}

T['Make ID for Bobby’s public key'] = function(test) {
	id = miniLockLib.makeID(Alice.publicKey)
	test.same(id, Alice.miniLockID)
	test.done()
}

T['Can’t make ID for undefined key'] = function(test) {
	try {
		miniLockLib.makeID(undefined)
	}
	catch (error) {
		test.same(error, 'miniLockLib.makeID() received undefined public key.', error)
		test.done()
	}
}

T['Can’t make ID for key that is too short'] = function(test) {
	try {
		miniLockLib.makeID(new Uint8Array(16))
	}
	catch (error) {
		test.same(error, 'miniLockLib.makeID() public key parameter was too short.', error)
		test.done()
	}
}

T['Can’t make ID for key that is too long'] = function(test) {
	try {
		miniLockLib.makeID(new Uint8Array(64))
	}
	catch (error) {
		test.same(error, 'miniLockLib.makeID() public key parameter was too long.', error)
		test.done()
	}
}

}) // End of top-level function body.
