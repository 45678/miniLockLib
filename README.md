`miniLockLib` is a fly-by-the-seat-of-your-pants implementation of the [miniLock](http://minilock.io/) file encryption specification. It is designed to perform miniLock encryption and decryption operations in your own Javascript web programs.

#### Setup


Download
 [`miniLockLib.js`](https://raw.githubusercontent.com/45678/miniLockLib/master/scripts/miniLockLib.js) and [`miniLockCryptoWorker.js`](https://raw.githubusercontent.com/45678/miniLockLib/master/scripts/miniLockCryptoWorker.js) and place them on your web server. Be aware that miniLockLib will not work with the `file://` protocol because it uses a `Worker` for background tasks.
 
Include `miniLockLib.js` with a script tag on your web page:

```
<script src="/scripts/miniLockLib.js" charset="utf-8"></script>
```

You should also redefine `miniLockLib.pathToScripts` so that the crypto worker can be loaded reliably on your site. Add a line like this to your program to configure it:

```
miniLockLib.pathToScripts = '/scripts'
```

#### Examples

Call `getKeyPair` with `secretPhrase` and `emailAddress` to get a pair of `keys`:

```
miniLockLib.getKeyPair(secretPhrase, emailAddress, function(keys){
   keys.publicKey is a 32-bit Uint8Array
   keys.secretKey is a 32-bit Uint8Array
})
```

Pass `file`, `name`, `keys` and `miniLockIDs` when you `encrypt` a file:

```
miniLockLib.encrypt({
  file: arrayBufferOfBinaryData,
  name: 'sensitive_document.txt'
  keys: {publicKey: Uint8Array, secretKey: Uint8Array},
  miniLockIDs: [aliceID, bobbyID, ...]
  callback: function(error, encrypted) {
    encrypted.data is a Blob of the encrypted data
    encrypted.data.size is the Number of bytes in the encrypted file
    encrypted.data.type is 'application/minilock'
    encrypted.name is 'sensitive document.txt.minilock'
    encrypted.senderID is the miniLock ID of the person who encrypted the file
  }
})
```

Pass `file` and `keys` when you `decrypt` a file:

```
miniLockLib.decrypt({
  file: arrayBufferOfBinaryData,
  keys: {publicKey: Uint8Array, secretKey: Uint8Array},
  callback: function(error, decrypted) {
    decrypted.data is a Blob of the decrypted data
    decrypted.data.size is the Number of bytes in the decrypted file 
    decrypted.name is the decrypted name of file as a String
    decrypted.senderID is the miniLock ID of the person who encrypted the file
  }
})
```

[Find more examples, and all the documentation, in the source code](https://github.com/45678/miniLockLib/blob/master/miniLockLib.coffee).

#### Sources

`miniLockLib` is composed of code from seven dandy little projects:

`miniLockCryptoWorker.js` is a copy of the crypto worker from the [official miniLock repository](https://github.com/kaepora/miniLock) created and maintained by Nadim Kobeissi. It has been modified to import `miniLockLib.js` instead of importing all its dependencies individually. The worker is responsible for processing `encrypt` and `decrypt` operations in the background.

`Base58.js` is a copy of the [cryptocoinjs bs58 library](https://github.com/cryptocoinjs/bs58). It has been modified to work in a web agent window instead of a node.js environment. And the filename was changed to match the global `Base58` address that it defines. `Base58` is used to encode and decode miniLock IDs.

`BLAKE2s.js` is an unmodified copy of Dmitry Chestnykh’s [blake2s-js project](https://github.com/dchest/blake2s-js). The filename of the script was renamed to match the global `BLAKE2s` address that it defines.

`nacl.js` is a copy of the [tweetnacl-js crypto library](https://github.com/dchest/tweetnacl-js) written by Dmitry Chestnykh. It has been modified to assign itself to `this` instead of `window` so that it can be imported seamlessly into the crypto worker. `nacl` is used throughout `miniLockLib` for a variety of cryptographic functions.

`nacl-stream.js` is an unmodified copy of the [tweetnacl-js streaming encryption library](https://github.com/dchest/nacl-stream-js) written by Dmitry Chestnykh. Streaming encryption is employed within the crypto worker.

`scrypt-async.js` is an unmodified script from Dmitry Chestnykh’s [scrypt-async-js](https://github.com/dchest/scrypt-async-js) project. It is used to derive a key pair from a secret phrase and email address. 

`zxcvbn.js` is an unmodified copy of Dropbox’s [zxcvbn password strength estimator](https://github.com/dropbox/zxcvbn). `miniLockLib` uses this library to calculate the entropy present in secret phrases.

#### Digging In

Run `npm install git+https://git@github.com/45678/miniLockLib.git` to get the source code.

Run `make` to build the `scripts`. All the source files for `miniLockLib.js` are saved in `lib`.

Run `npm start` to begin watching CoffeeScript files. Your saved changes will trigger compilation automatically.

Run `npm test` launch the test kit in Google Chrome.
