miniLockLib is a fly-by-the-seat-of-your-pants implementation of the [miniLock](http://minilock.io/) file encryption specification. It is designed for use in your own Javascript programs when you want to perform miniLock encryption and decryption operations.

To get started place the `miniLockLib.js` and `miniLockCryptoWorker.js` files on your web host and then include `miniLockLib.js` in a script tag on your web page, like this:

```
<script src="miniLockLib.js"></script>
```

`miniLockLib.js` includes all of its dependencies such as `Base58`, `BLAKE2s`, `nacl`, `nacl.stream`, `scrypt` and `zxcvbn`. `miniLockCryptoWorker.js` is loaded in a worker thread at runtime so you’ll need to keep it in the same location as `miniLockLib.js`.

