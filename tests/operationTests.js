new(function(){

Alice = {}
Alice.secretPhrase = 'lions and tigers are not the only ones i am worried about'
Alice.emailAddress = 'alice@example.com'
Alice.publicKey    = Base58.decode('3dz7VdGxZYTDQHHgXij2wgV3GRBu4GzJ8SLuwmAVB4kR')
Alice.secretKey    = Base58.decode('DsMtZntcp7riiWy9ng1xZ29tMPZQ9ioHNzk2i1UyChkF')

var T = window.operationTests = this

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

function readFixture(name, callback) {
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


T['test.txt filesize is 20 bytes'] = function(test){
	readFixture('test.txt', function(error, buffer){
		test.same(buffer.size, 20)
		test.done(error)
	})
}

T['test.txt.minilock filesize is 962 bytes'] = function(test){
	readFixture('test.txt.minilock', function(error, buffer){
		test.same(buffer.size, 962)
		test.done(error)
	})
}

T['encrypt simple test file'] = function(test) {
	readFixture('test.txt', function(error, buffer){
		if (error) return test.done(error)
		miniLockLib.encrypt({
			file: buffer,
			name: 'test.txt',
			miniLockIDs: ['CeF5fM7SEdphjktdUbAXaMGm13m6mTZtbprtghvsMRYgw'],
			senderID: 'CeF5fM7SEdphjktdUbAXaMGm13m6mTZtbprtghvsMRYgw',
			senderSecretKey: Alice.secretKey,
			callback: function(error, encrypted) {
				test.same(Object.keys(encrypted), ['name', 'data', 'type', 'senderID'])
				test.same(encrypted.name, 'test.txt.minilock')
				test.ok(encrypted.data)
				test.same(encrypted.data.size, 962)
				test.same(encrypted.senderID, 'CeF5fM7SEdphjktdUbAXaMGm13m6mTZtbprtghvsMRYgw')
				test.done(error)
			}
		})
	})
}

T['decrypt simple test file'] = function(test) {
	readFixture('test.txt.minilock', function(error, buffer){
		if (error) return test.done(error)
		miniLockLib.decrypt({
			file: buffer,
			myMiniLockID: 'CeF5fM7SEdphjktdUbAXaMGm13m6mTZtbprtghvsMRYgw',
			mySecretKey: Alice.secretKey,
			callback: function(error, decrypted) {
				test.ok(decrypted)
				test.same(Object.keys(decrypted), ['name', 'data', 'type', 'senderID'])
				test.same(decrypted.name, 'test.txt')
				test.ok(decrypted.data, '')
				test.same(decrypted.type, '')
				test.same(decrypted.senderID, 'CeF5fM7SEdphjktdUbAXaMGm13m6mTZtbprtghvsMRYgw')
				test.done(error)
			}
		})
	})
}

T['encrypt official miniLock test.jpg'] = function(test) {
	readFixture('test.jpg', function(error, buffer){
		if (error) return test.done(error)
		miniLockLib.encrypt({
			file: buffer,
			name: 'test.jpg',
			miniLockIDs: ['dJYs5sVfSSvccahyEYPwXp7n3pbXeoTnuBWHEmEgi95fF', 'PHD4eUWB982LUexKj1oYoQryayreUeW1NJ6gmsTY7Xe12'],
			senderID: 'dJYs5sVfSSvccahyEYPwXp7n3pbXeoTnuBWHEmEgi95fF',
			senderSecretKey: Base58.decode('7S4YTmjkexJ2yeMAtoEKYc2wNMHseMqDH6YyBqKKkUon'),
			callback: function(error, encrypted) {
				test.same(Object.keys(encrypted), ['name', 'data', 'type', 'senderID'])
				test.same(encrypted.name, 'test.jpg.minilock')
				test.ok(encrypted.data)
				test.same(encrypted.data.size, 349779)
				test.same(encrypted.senderID, 'dJYs5sVfSSvccahyEYPwXp7n3pbXeoTnuBWHEmEgi95fF')
				test.done(error)
			}
		})
	})
}



// T['decrypt miniLock test.jpg'] = function(test){
// 	readFixture('test.jpg', function(error, file){
// 		if (error) return test.done(error)
// 		miniLockLib.encrypt({
// 			file: file,
// 			name: 'test.jpg',
// 			audience: ['dJYs5sVfSSvccahyEYPwXp7n3pbXeoTnuBWHEmEgi95fF', 'PHD4eUWB982LUexKj1oYoQryayreUeW1NJ6gmsTY7Xe12'],
// 			senderID: 'dJYs5sVfSSvccahyEYPwXp7n3pbXeoTnuBWHEmEgi95fF',
// 			senderSecretKey: Base58.decode('7S4YTmjkexJ2yeMAtoEKYc2wNMHseMqDH6YyBqKKkUon'),
// 			callback: function(error, encrypted){
// 				if (error) return test.done(error)
// 				
// 				var reader = new FileReader
// 				reader.readAsArrayBuffer(encrypted.data)
// 				reader.onload = function(event){
// 					var arrayBuffer = event.target.result
// 					miniLockLib.decrypt({
// 						file: arrayBuffer,
// 						myMiniLockId: 'PHD4eUWB982LUexKj1oYoQryayreUeW1NJ6gmsTY7Xe12',
// 						mySecretKey: Base58.decode('B47Ez1ftjTPSL5Mu74YaQ33WAbDjNcBwYWnx7Fp6kvmr'),
// 						callback: function(error, decrypted){
// 							test.same(Object.keys(decrypted), ['name', 'data', 'type', 'senderID'])
// 							test.same(decrypted.name, 'test.jpg')
// 							test.ok(encrypted.data)
// 							test.same(decrypted.data.size, 348291)
// 							test.same(decrypted.senderID, 'dJYs5sVfSSvccahyEYPwXp7n3pbXeoTnuBWHEmEgi95fF')
// 							test.done(error)
// 						}
// 					})
// 				}
// 			}
// 		})
// 	})
// }


}) // End of top-level function body.
