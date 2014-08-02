default: scripts/miniLockLib.js scripts/miniLockCryptoWorker.js

scripts/miniLockLib.js: miniLockLib.coffee lib/Base58.js lib/BLAKE2s.js lib/nacl.js lib/nacl-stream.js lib/scrypt-async.js lib/zxcvbn.js
	# Combine all the source files in `lib` to create miniLockLib.js in `scripts`.
	coffee --compile --output lib miniLockLib.coffee
	uglifyjs lib/base58.js \
	  lib/blake2s.js \
	  lib/nacl.js \
	  lib/nacl-stream.js \
	  lib/scrypt-async.js \
	  lib/zxcvbn.js \
	  lib/miniLockLib.js \
	  --beautify --screw-ie8 \
	  > scripts/miniLockLib.js

scripts/miniLockCryptoWorker.js:
	# Make a copy of the official miniLock crypto worker and replace numerous 
	# importScripts(...) statements with one importScripts('miniLockLib.js').
	cat node_modules/miniLock/src/js/workers/crypto.js \
	  | sed "s/var window = {}/importScripts('miniLockLib.js')/" \
	  | sed "9,17d" \
	  > scripts/miniLockCryptoWorker.js

lib/Base58.js:
	# Download bs58.js. Modify it to work in a window or a worker. And then rename
	# it to Base58.js to match its runtime address. Saved in `lib`.
	curl -s https://raw.githubusercontent.com/cryptocoinjs/bs58/master/lib/bs58.js \
	  | sed "s/var assert = require('assert')/Base58 = {}/" \
	  | sed "s/assert(c in ALPHABET_MAP, 'Non-base58 character')/if (ALPHABET.indexOf(c) === -1) throw 'Non-base58 character'/" \
	  | sed "s/var ALPHABET =/ALPHABET =/" \
	  | sed "s/var ALPHABET_MAP =/ALPHABET_MAP =/" \
	  | sed "s/ALPHABET/Base58.ALPHABET/g" \
	  | sed "s/var BASE = 58/BASE = 58/" \
	  | sed "s/BASE/Base58.BASE/" \
	  | sed "s/function encode/Base58.encode = function/" \
	  | sed "s/function decode/Base58.decode = function/" \
	  | sed "s/Buffer/Uint8Array/" \
	  | sed "81,84d" \
	  | uglifyjs --beautify --wrap=Base58 \
	  > lib/Base58.js

lib/BLAKE2s.js:
	# Download BLAKE2s.js and save it in `lib`.
	curl -s https://raw.githubusercontent.com/dchest/blake2s-js/master/blake2s.js \
	  > lib/BLAKE2s.js

lib/nacl.js:
	# Make a copy of nacl.js in `lib` that assigns itself to `this` instead of 
	# `window` so that it can be imported seamlessly into a `Worker`.
	cat node_modules/tweetnacl/nacl.js \
	  | sed 's/window.nacl = window.nacl || {}/this.nacl = {}/' \
	  > lib/nacl.js

lib/nacl-stream.js:
	# Make a copy of nacl-stream.js in `lib`.
	cat node_modules/nacl-stream/nacl-stream.js \
	  > lib/nacl-stream.js

lib/scrypt-async.js:
	# Download scrypt-async.js and save it in `lib`.
	curl -s https://raw.githubusercontent.com/dchest/scrypt-async-js/master/scrypt-async.js \
	  > lib/scrypt-async.js

lib/zxcvbn.js:
	# Make a copy of zxcvbn.js in `lib`.
	cat node_modules/zxcvbn/zxcvbn.js \
	  > lib/zxcvbn.js

clean:
	rm -f lib/*.js
	rm -f scripts/miniLockLib.js
	rm -f scripts/miniLockCryptoWorker.js
	
install:
	mkdir ~/.pow/minilocklib
	ln -s $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST)))) ~/.pow/minilocklib/public

uninstall:
	rm -rf ~/.pow/minilocklib
