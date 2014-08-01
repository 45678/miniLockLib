// -----------------------
// Initialization
// -----------------------
'use strict';

/*jshint -W079 */
importScripts('miniLockLib.js')
/*jshint +W079 */

// Chunk size (in bytes)
// Warning: Must not be less than 256 bytes
var chunkSize = 1024 * 1024 * 1

// -----------------------
// Utility functions
// -----------------------

var base64Match = new RegExp(
	'^(?:[A-Za-z0-9+\/]{4})*(?:[A-Za-z0-9+\/]{2}==|[A-Za-z0-9+\/]{3}=)?$'
)

var base58Match = new RegExp(
	'^[1-9ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz]+$'
)

// Input: String
// Output: Boolean
// Notes: Validates if string is a proper miniLock ID.
var validateID = function(id) {
	if (
		(id.length > 55) ||
		(id.length < 40)
	) {
		return false
	}
	if (!base58Match.test(id)) {
		return false
	}
	var bytes = Base58.decode(id)
	if (bytes.length !== 33) {
		return false
	}
	var hash = new BLAKE2s(1)
	hash.update(bytes.subarray(0, 32))
	if (hash.digest()[0] !== bytes[32]) {
		return false
	}
	return true
}

// Input: Nonce (Base64) (String), Expected nonce length in bytes (Number)
// Output: Boolean
// Notes: Validates if string is a proper nonce.
var validateNonce = function(nonce, expectedLength) {
	if (
		(nonce.length > 40) ||
		(nonce.length < 10)
	) {
		return false
	}
	if (base64Match.test(nonce)) {
		var bytes = nacl.util.decodeBase64(nonce)
		return bytes.length === expectedLength
	}
	return false
}

// Input: String
// Output: Boolean
// Notes: Validates if string is a proper symmetric key.
var validateKey = function(key) {
	if (
		(key.length > 50) ||
		(key.length < 40)
	) {
		return false
	}
	if (base64Match.test(key)) {
		var bytes = nacl.util.decodeBase64(key)
		return bytes.length === 32
	}
	return false
}

var validateEphemeral = validateKey

// Input: Number
// Output: Number as 4-byte Uint8Array
var numberToByteArray = function(n) {
    var byteArray = [0, 0, 0, 0]
    for (var i = byteArray.length - 1; i >= 0; i--) {
        byteArray[i] = n & 255
		n = n >> 8
    }
    return new Uint8Array(byteArray)
}

// Input: 4-byte Uint8Array
// Output: ByteArray converter to number
var byteArrayToNumber = function(byteArray) {
	var n = 0
	for (var i = 0; i < byteArray.length; i++) {
		n += byteArray[i]
		if (i < byteArray.length-1) {
			n = n << 8
		}
	}
	return n
}

// -----------------------
// Cryptographic functions
// -----------------------

// Receive a message to perform a certain operation.
// Input: Object:
//	{
//		operation: Type of operation ('encrypt' or 'decrypt'),
//		data: Data to encrypt/decrypt (Uint8Array),
//		name: File name (String),
//		saveName: Name to use for saving resulting file (String),
//		fileKey: 32-byte key used for file encryption (Uint8Array),
//		fileNonce: 16-byte nonce used for file encryption/decryption (Uint8Array),
//		decryptInfoNonces: Array of 24-byte nonces (Uint8Array) to be used to encrypt
//			decryptInfo and fileInfo objects (one for each recipient)
//		ephemeral: {
//			publicKey: Ephemeral Curve25519 public key (Uint8Array),
//			secretKey: Ephemeral Curve25519 secret key (Uint8Array)
//		} (Only used for encryption)
//		miniLockIDs: Array of (Base58) miniLock IDs to encrypt to (not used for 'decrypt' operation),
//		myMiniLockID: Sender's miniLock ID (String),
//		mySecretKey: Sender's secret key (Uint8Array)
//	}
// Result: When finished, the worker will return the result
// 	which is supposed to be caught and processed by
//	the miniLock.crypto.worker.onmessage() function
//	in miniLock.js.
// Notes: A miniLock-encrypted file's first 8 bytes are always the following:
//	0x6d, 0x69, 0x6e, 0x69,
//	0x4c, 0x6f, 0x63, 0x6b,
//	Those 8 bytes are then followed by an 4-byte little-endian value indicating the byte length
//	of the file header, which is the following JSON object (binary-encoded):
//	{
//		version: Version of the miniLock protocol used for this file (Currently 1) (Number)
//		ephemeral: Public key from ephemeral key pair used to encrypt decryptInfo object (Base64),
//		decryptInfo: {
//			(One copy of the below object for every recipient)
//			Unique nonce for decrypting this object (Base64): {
//				senderID: Sender's miniLock ID (Base58),
//				recipientID: miniLock ID of this recipient (used for verfication) (Base58),
//				fileInfo: {
//					fileKey: Key for file decryption (Base64),
//					fileNonce: Nonce for file decryption (Base64),
//					fileHash: BLAKE2 hash (32 bytes) of the ciphertext bytes. (Base64)
//				} (fileInfo is encrypted to recipient's public key using long-term key pair) (Base64),
//			} (encrypted to recipient's public key using ephemeral key pair) (Base64)
//
//		}
//	}
//	The file's filename is padded with 0x00 bytes until its length equals 256 bytes.
//	The filename is then prepended to the plaintext prior to encryption and is encrypted as its own chunk.
//	Note that the nonce used to encrypt decryptInfo is the same as the one used to encrypt fileInfo.
//	Nonce reuse in this scenario is permitted since we are encrypting using different keys.
//	The ciphertext in binary format is appended after the header.
onmessage = function(message) {
message = message.data

// We have received a request to encrypt
if (message.operation === 'encrypt') {
	(function() {
		var header = {
			version: 1,
			ephemeral: nacl.util.encodeBase64(message.ephemeral.publicKey),
			decryptInfo: {}
		}
		var streamEncryptor = nacl.stream.createEncryptor(
			message.fileKey,
			message.fileNonce,
			chunkSize
		)
		var paddedFileName = message.name
		while (paddedFileName.length < 256) {
			paddedFileName += String.fromCharCode(0x00)
		}
		var fileHash = new BLAKE2s(32)
		var encrypted = []
		var encryptedChunk
		encryptedChunk = streamEncryptor.encryptChunk(
			nacl.util.decodeUTF8(paddedFileName),
			false
		)
		fileHash.update(encryptedChunk)
		encrypted.push(encryptedChunk)
		for (var c = 0; c < message.data.length; c += chunkSize) {
			if (c >= (message.data.length - chunkSize)) {
				encryptedChunk = streamEncryptor.encryptChunk(
					message.data.subarray(c),
					true
				)
			}
			else {
				encryptedChunk = streamEncryptor.encryptChunk(
					message.data.subarray(c, c + chunkSize),
					false
				)
			}
			if (!encryptedChunk) {
				postMessage({
					operation: 'encrypt',
					error: 1
				})
				throw new Error('miniLock: Encryption failed - general encryption error')
				return false
			}
			fileHash.update(encryptedChunk)
			encrypted.push(encryptedChunk)
			postMessage({
				operation: 'encrypt',
				progress: c + chunkSize,
				total: message.data.length
			})
		}
		streamEncryptor.clean()
		for (var i = 0; i < message.miniLockIDs.length; i++) {
			var decryptInfo = {
				senderID: message.myMiniLockID,
				recipientID: message.miniLockIDs[i],
				fileInfo: {
					fileKey: nacl.util.encodeBase64(message.fileKey),
					fileNonce: nacl.util.encodeBase64(message.fileNonce),
					fileHash: nacl.util.encodeBase64(fileHash.digest())
				}
			}
			decryptInfo.fileInfo = nacl.util.encodeBase64(nacl.box(
				nacl.util.decodeUTF8(JSON.stringify(decryptInfo.fileInfo)),
				message.decryptInfoNonces[i],
				Base58.decode(message.miniLockIDs[i]).subarray(0, 32),
				message.mySecretKey
			))
			decryptInfo = nacl.util.encodeBase64(nacl.box(
				nacl.util.decodeUTF8(JSON.stringify(decryptInfo)),
				message.decryptInfoNonces[i],
				Base58.decode(message.miniLockIDs[i]).subarray(0, 32),
				message.ephemeral.secretKey
			))
			header.decryptInfo[
				nacl.util.encodeBase64(message.decryptInfoNonces[i])
			] = decryptInfo
		}
		header = JSON.stringify(header)
		encrypted.unshift(
			'miniLock',
			numberToByteArray(header.length),
			header
		)
		encrypted = (new FileReaderSync()).readAsArrayBuffer(new Blob(encrypted))
		postMessage({
			operation: 'encrypt',
			blob: encrypted,
			name: message.name,
			saveName: message.saveName,
			senderID: message.myMiniLockID,
			callback: message.callback
		}, [encrypted])
		encrypted = null
	})()
}


// We have received a request to decrypt
if (message.operation === 'decrypt') {
	(function() {
		var header, headerLength
		try {
			headerLength = byteArrayToNumber(
				new Uint8Array(message.data.subarray(8, 12))
			)
			header = nacl.util.encodeUTF8(
				message.data.subarray(12, headerLength + 12)
			)
			header = JSON.parse(header)
			message.data = message.data.subarray(
				12 + headerLength,
				message.data.length
			)
		}
		catch(error) {
			postMessage({
				operation: 'decrypt',
				error: 3
			})
			throw new Error('miniLock: Decryption failed - could not parse header')
			return false
		}
		if (
			!header.hasOwnProperty('version')
			|| header.version !== 1
		) {
			postMessage({
				operation: 'decrypt',
				error: 4
			})
			throw new Error('miniLock: Decryption failed - invalid header version')
			return false
		}
		if (
			!header.hasOwnProperty('ephemeral')
			|| !validateEphemeral(header.ephemeral)
		) {
			postMessage({
				operation: 'decrypt',
				error: 5
			})
			throw new Error('miniLock: Decryption failed - could not validate sender ID')
			return false
		}
		// Attempt decryptInfo decryptions until one succeeds
		var actualDecryptInfo      = null
		var actualDecryptInfoNonce = null
		var actualFileInfo         = null
		for (var i in header.decryptInfo) {
			if (
				({}).hasOwnProperty.call(header.decryptInfo, i)
				&& validateNonce(i, 24)
			) {
				try {
					nacl.util.decodeBase64(header.decryptInfo[i])
				}
				catch(err) {
					postMessage({
						operation: 'decrypt',
						error: 3
					})
					throw new Error('miniLock: Decryption failed - could not parse header')
					return false
				}
				actualDecryptInfo = nacl.box.open(
					nacl.util.decodeBase64(header.decryptInfo[i]),
					nacl.util.decodeBase64(i),
					nacl.util.decodeBase64(header.ephemeral),
					message.mySecretKey
				)
				if (actualDecryptInfo) {
					try {
						actualDecryptInfo = JSON.parse(
							nacl.util.encodeUTF8(actualDecryptInfo)
						)
						actualDecryptInfoNonce = nacl.util.decodeBase64(i)
					}
					catch(err) {
						postMessage({
							operation: 'decrypt',
							error: 3
						})
						throw new Error('miniLock: Decryption failed - could not parse header')
						return false
					}
					break
				}
			}
		}
		if (
			!actualDecryptInfo
			|| !({}).hasOwnProperty.call(actualDecryptInfo, 'recipientID')
			|| actualDecryptInfo.recipientID !== message.myMiniLockID
		) {
			postMessage({
				operation: 'decrypt',
				error: 6
			})
			throw new Error('miniLock: Decryption failed - File is not encrypted for this recipient')
			return false
		}
		if (
			!({}).hasOwnProperty.call(actualDecryptInfo, 'fileInfo')
			|| !({}).hasOwnProperty.call(actualDecryptInfo, 'senderID')
			|| !validateID(actualDecryptInfo.senderID)
		) {
			postMessage({
				operation: 'decrypt',
				error: 3
			})
			throw new Error('miniLock: Decryption failed - could not parse header')
			return false
		}
		try {
			actualFileInfo = nacl.box.open(
				nacl.util.decodeBase64(actualDecryptInfo.fileInfo),
				actualDecryptInfoNonce,
				Base58.decode(actualDecryptInfo.senderID).subarray(0, 32),
				message.mySecretKey
			)
			actualFileInfo = JSON.parse(
				nacl.util.encodeUTF8(actualFileInfo)
			)
			actualFileInfo.fileKey   = nacl.util.decodeBase64(actualFileInfo.fileKey)
			actualFileInfo.fileNonce = nacl.util.decodeBase64(actualFileInfo.fileNonce)
			actualFileInfo.fileHash  = nacl.util.decodeBase64(actualFileInfo.fileHash)
		}
		catch(err) {
			postMessage({
				operation: 'decrypt',
				error: 3
			})
			throw new Error('miniLock: Decryption failed - could not parse header')
			return false
		}
		var streamDecryptor = nacl.stream.createDecryptor(
			actualFileInfo.fileKey,
			actualFileInfo.fileNonce,
			chunkSize
		)
		var fileHash = new BLAKE2s(32)
		var decrypted = []
		var chunk, decryptedChunk
		chunk = message.data.subarray(0, 4 + 16 + 256)
		decryptedChunk = streamDecryptor.decryptChunk(
			chunk,
			false
		)
		fileHash.update(chunk)
		decrypted.push(decryptedChunk)
		for (var c = 4 + 16 + 256; c < message.data.length; c += (4 + 16 + chunkSize)) {
			if (c >= (message.data.length - (4 + 16 + chunkSize))) {
				chunk = message.data.subarray(c)
				decryptedChunk = streamDecryptor.decryptChunk(
					chunk,
					true
				)
			}
			else {
				chunk = message.data.subarray(c, c + (4 + 16 + chunkSize))
				decryptedChunk = streamDecryptor.decryptChunk(
					chunk,
					false
				)
			}
			if (!decryptedChunk) {
				postMessage({
					operation: 'decrypt',
					error: 2
				})
				throw new Error('miniLock: Decryption failed - general decryption error')
				return false
			}
			fileHash.update(chunk)
			decrypted.push(decryptedChunk)
			postMessage({
				operation: 'decrypt',
				progress: c + chunkSize,
				total: message.data.length
			})
		}
		streamDecryptor.clean()
		var fileName = ''
		try {
			fileName = nacl.util.encodeUTF8(decrypted[0])
			decrypted.splice(0, 1)
			while (
				fileName[fileName.length - 1] === String.fromCharCode(0x00)
			) {
				fileName = fileName.slice(0, -1)
			}
			decrypted = (new FileReaderSync()).readAsArrayBuffer(
				new Blob(decrypted)
			)
		}
		catch(err) {
			postMessage({
				operation: 'decrypt',
				error: 2
			})
			throw new Error('miniLock: Decryption failed - general decryption error')
			return false
		}
		if (
			!nacl.verify(
				new Uint8Array(fileHash.digest()),
				actualFileInfo.fileHash
			)
		) {
			postMessage({
				operation: 'decrypt',
				error: 7
			})
			throw new Error('miniLock: Decryption failed - could not validate file contents after decryption')
			return false
		}
		postMessage({
			operation: 'decrypt',
			blob: decrypted,
			name: fileName,
			saveName: fileName,
			senderID: actualDecryptInfo.senderID,
			callback: message.callback
		}, [decrypted])
		decrypted = null
	})()
}

}
