`miniLockLib` is a little [miniLock](http://minilock.io/) library.

Download [`miniLockLib.js`](https://raw.githubusercontent.com/45678/miniLockLib/master/scripts/miniLockLib.js) and add it to your page with a `<script>` tag:

    <script src="miniLockLib.js" charset="utf-8"></script>

Now you are ready to call `miniLockLib` methods from your Javascript program...

__Examples__

Call `miniLockLib.makeKeyPair` with a `secretPhrase` and `emailAddress` to get a pair of `keys`:

    miniLockLib.makeKeyPair(secretPhrase, emailAddress, function(error, keys){
      if (keys) {
        keys.publicKey is a Uint8Array
        keys.secretKey is a Uint8Array
        error is undefined
      } else {
        error is a String explaining the failure
        keys is undefined
       }
    })

Pass `data`, `name`, `keys` and `miniLockIDs` when you `encrypt` a file:

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

Pass `data` and `keys` when you `decrypt` a file:

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

[See more examples in the tests](https://github.com/45678/miniLockLib/blob/master/tests/0%20A%20demo%20of...%20tests.coffee) or [read the source code](https://github.com/45678/miniLockLib/blob/master/library/index.coffee) for all the terrible details.

__Sources__

`miniLockLib` is composed of code from several dandy little projects:

`Base58.js` is a copy of the [cryptocoinjs bs58 library](https://github.com/cryptocoinjs/bs58). It has been modified to work in a web agent window instead of a node.js environment. And the filename was changed to match the global `Base58` address that it defines. `Base58` is used to encode and decode miniLock IDs.

`BLAKE2s.js` provides a subclass of [Dmitry Chestnykh’s implementation of the BLAKE2s](https://github.com/dchest/blake2s-js) cryptographic hash function. `miniLockLib` subclasses the original constructor to expose a modestly more convenient interface for its purposes.

`nacl.js` provides the [tweetnacl-js crypto library](https://github.com/dchest/tweetnacl-js) written by Dmitry Chestnykh & Devi Mandiri. This instance of `NaCl` is extended with Dmitry’s [streaming encryption library](https://github.com/dchest/nacl-stream-js). `miniLockLib` relies on `NaCl` for a variety of cryptographic and encoding functions.

`scrypt-async.js` is an unmodified copy of Dmitry Chestnykh’s [scrypt-async-js](https://github.com/dchest/scrypt-async-js) project. It is used to derive a key pair from a secret phrase and email address with the curve25519 encryption scheme.

`zxcvbn.js` is an unmodified copy of Dropbox’s [zxcvbn password strength estimator](https://github.com/dropbox/zxcvbn). `miniLockLib` uses this library to calculate the entropy present in secret phrases.

__Digging In__

`npm install 45678/miniLockLib.git` to get the source code.

`npm test` launch the test suite in Google Chrome.

`npm start` to begin watching CoffeeScript files. Your saved changes will trigger automatic re-compilation.

Run `make` to re-compile the `scripts`.

CoffeeScript library files are compiled to the `library.compiled` folder and saved as `scripts/miniLockLib.js`.

CoffeeScript test files are compiled to the `tests.compiled` folder and saved as `scripts/tests.js`.
