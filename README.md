`miniLockLib` is a little [miniLock](http://minilock.io/) library for [ECMAScript](http://www.ecmascript.org/).

Download [`miniLockLib.js`](https://raw.githubusercontent.com/45678/miniLockLib/master/scripts/miniLockLib.js) and add it to your page with a `<script>` tag:

    <script src="miniLockLib.js" charset="utf-8"></script>

Or `npm install 45678/miniLockLib.git` and require it in your program with:

    miniLockLib = require('miniLockLib')

Now you are ready to call `miniLockLib` methods from your computer program...

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

[More examples](https://github.com/45678/miniLockLib/blob/master/tests/0%20A%20demo%20of...%20tests.coffee) in the tests or [read the source code](https://github.com/45678/miniLockLib/blob/master/library/index.coffee) for all the terrible details.

__Demos__

[miniLock file format version 1](https://45678.github.io/minilock-file-formats/1.html)

[miniLock file format version 2](https://45678.github.io/minilock-file-formats/2.html)

[Is it a miniLock ID?](https://45678.github.io/is-it-a-minilock-id/)

[miniLock ID inspector](https://45678.github.io/minilock-id-inspector/)


__Sources__

`miniLockLib` is composed of code from several dandy little projects:

`miniLockLib.Base58` is a copy of the [cryptocoinjs bs58 library](https://github.com/cryptocoinjs/bs58).
It has been modified to work in a web agent window instead of a node.js environment.
And the filename of the script was changed to match the `Base58` address that it defines.
`Base58` is used to encode and decode miniLock IDs.

`miniLockLib.BLAKE2s` is a subclass of [Dmitry Chestnykh’s implementation of the BLAKE2s](https://github.com/dchest/blake2s-js) cryptographic hash function.
`miniLockLib` subclasses the original constructor to expose a modestly more convenient interface for its purposes.

`miniLockLib.NaCl` is the [tweetnacl-js](https://github.com/dchest/tweetnacl-js) crypto library written by Dmitry Chestnykh & Devi Mandiri.
This instance of `NaCl` is extended with Dmitry’s [streaming encryption library](https://github.com/dchest/nacl-stream-js).
`miniLockLib` relies on `NaCl` for a host of cryptographic and encoding functions.

`miniLockLib.scrypt` is a copy of `scrypt-async.js` from the [scrypt-async-js](https://github.com/dchest/scrypt-async-js) project which was also written by Mr. Chestnykh.
`scrypt` derives a key pair from a secret and a salt with the curve25519 encryption scheme.

`miniLockLib.zxcvbn` is Dropbox’s [zxcvbn password strength estimator](https://github.com/dropbox/zxcvbn).
`miniLockLib` relies on this library to calculate the entropy present in secret phrases.


__Digging In__

`git clone https://github.com/45678/miniLockLib.git` to get the source code.

`make` to re-compile JavaScript files in the `library.compiled`, `tests.compiled` and `website` folders.

The CoffeeScript files in the `library` folder are compiled to the `library.compiled` folder.
And then all files in `library.compiled` are combined and written to `website/miniLockLib.js`.

The CoffeeScript files in the `test` folder are compiled to the `tests.compiled` folder.
And then all files in `tests.compiled` are combined and written to `website/tests.js`.

`npm test` to compile everthing and open the test suite in Google Chrome.

`make clean` to start over.
