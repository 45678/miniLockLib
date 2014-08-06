`miniLockLib` is a little [miniLock](http://minilock.io/) library.

Download [`miniLockLib.js`](https://raw.githubusercontent.com/45678/miniLockLib/master/scripts/miniLockLib.js) and add it to your page with a `<script>` tag:

```
<script src="miniLockLib.js" charset="utf-8"></script>
```

Now you are ready to call methods on `miniLockLib` from your Javascript program...

__Examples__

Call `getKeyPair` with `secretPhrase` and `emailAddress` to get a pair of `keys`:

```
miniLockLib.getKeyPair(secretPhrase, emailAddress, function(keys){
   keys.publicKey is a Uint8Array
   keys.secretKey is a Uint8Array
})
```

Pass `data`, `name`, `keys` and `miniLockIDs` when you `encrypt` a file:

```
miniLockLib.encrypt({
  data: blob,
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

Pass `data` and `keys` when you `decrypt` a file:

```
miniLockLib.decrypt({
  data: blob,
  keys: {publicKey: Uint8Array, secretKey: Uint8Array},
  callback: function(error, decrypted) {
    decrypted.data is a Blob of the decrypted data
    decrypted.data.size is the Number of bytes in the decrypted file 
    decrypted.name is the decrypted name of file as a String
    decrypted.senderID is the miniLock ID of the person who encrypted the file
  }
})
```

[Find more examples, and all the documentation, in the source code](https://github.com/45678/miniLockLib/blob/master/index.coffee).

__Sources__

`miniLockLib` is composed of code from six dandy little projects:

`Base58.js` is a copy of the [cryptocoinjs bs58 library](https://github.com/cryptocoinjs/bs58). It has been modified to work in a web agent window instead of a node.js environment. And the filename was changed to match the global `Base58` address that it defines. `Base58` is used to encode and decode miniLock IDs.

`BLAKE2s.js` is an unmodified copy of Dmitry Chestnykh’s [blake2s-js project](https://github.com/dchest/blake2s-js). The filename of the script was renamed to match the global `BLAKE2s` address that it defines.

`nacl.js` is a copy of the [tweetnacl-js crypto library](https://github.com/dchest/tweetnacl-js) written by Dmitry Chestnykh. It has been modified to assign itself to `this` instead of `window` so that it can be imported seamlessly into the crypto worker. `nacl` is used throughout `miniLockLib` for a variety of cryptographic functions.

`nacl-stream.js` is an unmodified copy of the [tweetnacl-js streaming encryption library](https://github.com/dchest/nacl-stream-js) written by Dmitry Chestnykh. Streaming encryption is employed in the crypto worker.

`scrypt-async.js` is an unmodified script from Dmitry Chestnykh’s [scrypt-async-js](https://github.com/dchest/scrypt-async-js) project. It is used to derive a key pair from a secret phrase and email address. 

`zxcvbn.js` is an unmodified copy of Dropbox’s [zxcvbn password strength estimator](https://github.com/dropbox/zxcvbn). `miniLockLib` uses this library to calculate the entropy present in secret phrases. 

__Digging In__

`npm install git+https://git@github.com/45678/miniLockLib.git` to get the source code.

`make` to build the `scripts`. All the source files for `miniLockLib.js` are saved in `lib`.

`npm start` to begin watching CoffeeScript files. Your saved changes will trigger automatic re-compilation.

`npm test` launch the test kit in Google Chrome.
