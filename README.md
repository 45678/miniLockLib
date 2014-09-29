[<img src="https://raw.githubusercontent.com/45678/miniLockLib/master/website/poster.png">](https://45678.github.io/miniLockLib/)

Get [`miniLockLib.js`](https://raw.githubusercontent.com/45678/miniLockLib/master/miniLockLib.js) and add it to your web page with a script tag:

    <script src="miniLockLib.js" charset="utf-8"></script>

Or `npm install 45678/miniLockLib.git` and require it in your computer program with:

    miniLockLib = require('miniLockLib')

Now you are ready to call `miniLockLib` methods...

__Examples__

Call `miniLockLib.makeKeyPair` with a `secretPhrase` and `emailAddress` to get a pair of `keys`:

    miniLockLib.makeKeyPair(secretPhrase, emailAddress, function(error, keys){
      if (keys) {
        keys.publicKey is instanceof Uint8Array
        keys.secretKey is instanceof Uint8Array
      } else {
        console.error(error)
       }
    })

Pass `data`, `name`, `keys` and `miniLockIDs` when you `encrypt` a file:

    miniLockLib.encrypt({
      data: instanceof Blob or File,
      name: 'Untitled.txt'
      keys: {publicKey: Uint8Array, secretKey: Uint8Array},
      miniLockIDs: [myID, aliceID, bobbyID, ...]
      callback: function(error, encrypted) {
        if (encrypted) {
          encrypted.data is an instanceof Blob
          encrypted.data.size is the Number of bytes in the Blob
          encrypted.data.type is 'application/minilock'
          encrypted.name is 'Untitled.txt.minilock'
          encrypted.senderID identifies the owner of the keys
        } else {
          console.error(error)
        }
      }
    })

Pass `data` and `keys` when you `decrypt` a file:

    miniLockLib.decrypt({
      data: encrypted.data
      keys: {publicKey: Uint8Array, secretKey: Uint8Array},
      callback: function(error, decrypted) {
        if (decrypted) {
          decrypted.data is an instanceof Blob
          encrypted.data.size is the Number of bytes in the Blob
          encrypted.data.type is 'text/plain'
          decrypted.name is 'Untitled.txt'
          decrypted.senderID identifies the owner of the keys
        } else {
          console.error(error)
        }
      }
    })

__Digging In__

`git clone https://github.com/45678/miniLockLib.git` to get the source code.

`make` to compile [CoffeeScript](http://www.coffeescript.org/) files into [ECMAScript](http://www.ecmascript.org/) files in the `library.compiled`, `tests.compiled` and `website` folders.

`make clean` to start over.

`npm run tests` to open the test suite in a web agent `window`.
