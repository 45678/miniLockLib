new(function(){

Alice = {}
Alice.secretPhrase = 'lions and tigers are not the only ones i am worried about'
Alice.emailAddress = 'alice@example.com'
Alice.publicKey    = Base58.decode('3dz7VdGxZYTDQHHgXij2wgV3GRBu4GzJ8SLuwmAVB4kR')
Alice.secretKey    = Base58.decode('DsMtZntcp7riiWy9ng1xZ29tMPZQ9ioHNzk2i1UyChkF')

var T = window.keyPairTests = this

T['Alice’s secret phrase is acceptable to miniLock'] = function(test) {
	test.ok(miniLockLib.secretPhraseIsAcceptable(Alice.secretPhrase))
	test.done()
}

T['short secret phrase is unacceptable'] = function(test) {
	test.same(miniLockLib.secretPhraseIsAcceptable('My password is password'), false)
	test.done()
}

T['compute Alice’s keys from her secret phrase and email address'] = function(test) {
	miniLockLib.getKeyPair(Alice.secretPhrase, Alice.emailAddress, function(keys){
		test.same(Object.keys(keys), ['publicKey', 'secretKey'])
		test.same(keys.publicKey, Alice.publicKey)
		test.same(keys.secretKey, Alice.secretKey)
		test.done()
	})
}

T['make ID for Alice’s public key'] = function(test) {
	id = miniLockLib.makeID(Alice.publicKey)
	test.same(id, 'CeF5fM7SEdphjktdUbAXaMGm13m6mTZtbprtghvsMRYgw')
	test.done()
}

T['can’t make ID for undefined key'] = function(test) {
	try {
		miniLockLib.makeID(undefined)
	}
	catch (error) {
		test.same(error, 'miniLockLib.makeID() received undefined public key.', error)
		test.done()
	}
}

T['can’t make ID for key that is too short'] = function(test) {
	try {
		miniLockLib.makeID(new Uint8Array(16))
	}
	catch (error) {
		test.same(error, 'miniLockLib.makeID() public key parameter was too short.', error)
		test.done()
	}
}

T['can’t make ID for key that is too long'] = function(test) {
	try {
		miniLockLib.makeID(new Uint8Array(64))
	}
	catch (error) {
		test.same(error, 'miniLockLib.makeID() public key parameter was too long.', error)
		test.done()
	}
}

}) // End of top-level function body.
