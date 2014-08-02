new(function(){

var Alice = window.testFixtures.Alice
var Bobby = window.testFixtures.Bobby

var T = window.operationTests = this

function readFileFixture(name, callback) {
	var request = new XMLHttpRequest
	request.open('GET', '/tests/'+name, true)
	request.responseType = 'blob'
	request.onreadystatechange = function(event) {
		if (request.readyState === 4) {
			request.response.name = name
			readFileAsArrayBuffer(request.response, callback)
		}
	}
	request.send()
}

function readFileAsArrayBuffer(file, callback, errorCallback) {
	var reader = new FileReader()
	reader.onload = function(readerEvent) {
		callback(undefined, {
			name: file.name,
			size: file.size,
			data: readerEvent.target.result // (ArrayBuffer)
		})
	}
	reader.onerror = callback
	reader.readAsArrayBuffer(file)
}

T['Encrypt private file for Alice'] = function(test) {
	readFileFixture('basic.txt', function(error, buffer){
		if (error) return test.done(error)
		miniLockLib.encrypt({
			file: buffer,
			name: 'alice.txt',
			keys: Alice.keys,
			miniLockIDs: [Alice.miniLockID],
			callback: function(error, encrypted) {
				test.same(Object.keys(encrypted), ['name', 'data', 'senderID'])
				test.same(encrypted.name, 'alice.txt.minilock')
				test.ok(encrypted.data)
				test.same(encrypted.data.size, 962)
				test.same(encrypted.data.type, 'application/minilock')
				test.same(encrypted.senderID, Alice.miniLockID)
				test.done(error)
			}
		})
	})
}

T['Encrypt file for Alice & Bobby'] = function(test) {
	readFileFixture('basic.txt', function(error, buffer){
		if (error) return test.done(error)
		miniLockLib.encrypt({
			file: buffer,
			name: 'alice_and_bobby.txt',
			keys: Alice.keys,
			miniLockIDs: [Alice.miniLockID, Bobby.miniLockID],
			callback: function(error, encrypted) {
				test.same(Object.keys(encrypted), ['name', 'data', 'senderID'])
				test.same(encrypted.name, 'alice_and_bobby.txt.minilock')
				test.ok(encrypted.data)
				test.same(encrypted.data.size, 1508)
				test.same(encrypted.data.type, 'application/minilock')
				test.same(encrypted.senderID, Alice.miniLockID)
				test.done(error)
			}
		})
	})
}

T['Alice can decrypt file her private file'] = function(test) {
	readFileFixture('alice.txt.minilock', function(error, buffer){
		if (error) return test.done(error)
		miniLockLib.decrypt({
			file: buffer,
			keys: Alice.keys,
			callback: function(error, decrypted) {
				test.ok(decrypted)
				test.same(Object.keys(decrypted), ['name', 'data', 'senderID'])
				test.same(decrypted.name, 'basic.txt')
				test.ok(decrypted.data, '')
				test.same(decrypted.data.size, 20)
				test.same(decrypted.senderID, Alice.miniLockID)
				test.done(error)
			}
		})
	})
}

T['Alice can decrypt file for Alice & Bobby'] = function(test) {
	readFileFixture('alice_and_bobby.txt.minilock', function(error, buffer){
		if (error) return test.done(error)
		miniLockLib.decrypt({
			file: buffer,
			keys: Alice.keys,
			callback: function(error, decrypted) {
				test.ok(decrypted)
				test.same(Object.keys(decrypted), ['name', 'data', 'senderID'])
				test.same(decrypted.name, 'basic.txt')
				test.ok(decrypted.data, '')
				test.same(decrypted.data.size, 20)
				test.same(decrypted.senderID, Alice.miniLockID)
				test.done(error)
			}
		})
	})
}

T['Bobby can decrypt file for Alice & Bobby'] = function(test) {
	readFileFixture('alice_and_bobby.txt.minilock', function(error, buffer){
		if (error) return test.done(error)
		miniLockLib.decrypt({
			file: buffer,
			keys: Bobby.keys,
			callback: function(error, decrypted) {
				test.ok(decrypted)
				test.same(Object.keys(decrypted), ['name', 'data', 'senderID'])
				test.same(decrypted.name, 'basic.txt')
				test.ok(decrypted.data, '')
				test.same(decrypted.data.size, 20)
				test.same(decrypted.senderID, Alice.miniLockID)
				test.done(error)
			}
		})
	})
}

T['Bobby can’t decrypt Alices’s private file'] = function(test) {
	readFileFixture('alice.txt.minilock', function(error, buffer){
		if (error) return test.done(error)
		miniLockLib.decrypt({
			file: buffer,
			keys: Bobby.keys,
			callback: function(error, decrypted) {
				console.info(error)
				test.same(error, 'This file does not seem to be encrypted for your miniLock ID. Check that you are logged in with the correct miniLock ID.')
				test.same(decrypted, undefined)
				test.done()
			}
		})
	})
}

// window.URL = window.webkitURL || window.URL		
// $(document.body).append('<a class="fileSaveLink">Download</a>')
// $('a.fileSaveLink').attr('download', encrypted.name)
// $('a.fileSaveLink').attr('href', window.URL.createObjectURL(encrypted.data))

}) // End of top-level function body.
