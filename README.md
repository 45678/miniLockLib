[<img src="https://raw.githubusercontent.com/45678/miniLockLib/master/website/poster.png">](https://45678.github.io/miniLockLib/)

Get [`miniLockLib.js`](https://45678.github.io/miniLockLib/miniLockLib.js) and add it to your web page with a script tag:

    <script src="miniLockLib.js" charset="utf-8"></script>

Or `npm install 45678/miniLockLib` and require it in your computer program with:

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

You will need [GNU Make](https://www.gnu.org/software/make/) and [Node.js](https://nodejs.org/en/) on your computer to compile, run and test the code in this project. If you can run `make --version` and `node --version` without errors on the command line then you should be all set. If you don’t already have a copy Node.js, we recommend you [download the installer for your operating system](https://nodejs.org/en/download/) from the official website.

`brew install caddy` to install [Caddy web server](https://caddyserver.com) for
simple testing.

`git clone https://github.com/45678/miniLockLib.git` to get the source code.

`cd miniLockLib`

`npm install -g browserify` which is needed to run `make`.

`npm install -g docco` which is needed to run `make`.

`npm install` to install local packages needed to run `make` tasks.

`make` to compile [CoffeeScript](http://www.coffeescript.org/) files into [ECMAScript](http://www.ecmascript.org/) files in the `library.compiled`, `tests.compiled` and `website` folders.

`make clean` to remove all generated files and start over.

Open a new terminal, and `cd miniLockLib` and start Caddy webserver by
running `caddy` which will start server on port `8888`.

`npm run test` in the original terminal to run both the NodeJS and Browser test
suites. A new browser window, using your default browser, will be opened and the
NodeJS tests will run in the console.
