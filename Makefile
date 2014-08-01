default: miniLockLib.js miniLockCryptoWorker.js

miniLockLib.js: dependencies/miniLockLib.js dependencies/Base58.js dependencies/BLAKE2s.js dependencies/nacl.js dependencies/scrypt-async.js
	# Combine source files to create `miniLockLib.js` script.
	uglifyjs dependencies/base58.js \
	  dependencies/blake2s.js \
	  dependencies/nacl.js \
	  node_modules/nacl-stream/nacl-stream.js \
	  dependencies/scrypt-async.js \
	  node_modules/zxcvbn/zxcvbn.js \
	  dependencies/miniLockLib.js \
	  --beautify --output miniLockLib.js --screw-ie8

miniLockCryptoWorker.js:
	# Make a copy of the official miniLock crypto worker and replace all of its 
	# importScripts(...) statements with: importScripts('miniLockLib.js')
	cat node_modules/miniLock/src/js/workers/crypto.js \
	  | sed "s/var window = {}/importScripts('miniLockLib.js')/" \
	  | sed "9,17d" \
	  > miniLockCryptoWorker.js

dependencies/miniLockLib.js:
	# Compile CoffeeScript source into Javascript and save it in `dependencies`.
	coffee --compile --output dependencies miniLockLib.coffee
	
dependencies/Base58.js:
	# Download bs58.js, modify it to work in a window or a worker and then rename
	# it to Base58.js to match its runtime address.
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
	 	> dependencies/Base58.js

dependencies/BLAKE2s.js:
	# Download BLAKE2s.js by Dmitry Chestnykh.
	curl -s https://raw.githubusercontent.com/dchest/blake2s-js/master/blake2s.js \
	  > dependencies/BLAKE2s.js

dependencies/nacl.js:
	# Make a copy of nacl.js that assigns itself to `this` instead of `window`
	# so that it can be imported seamlessly into the worker.
	cat node_modules/tweetnacl/nacl.js \
	  | sed 's/window.nacl = window.nacl || {}/this.nacl = {}/' \
	  > dependencies/nacl.js

dependencies/scrypt-async.js:
	# Download scrypt-async.js by Dmitry Chestnykh.
	curl -s https://raw.githubusercontent.com/dchest/scrypt-async-js/master/scrypt-async.js \
	  > dependencies/scrypt-async.js

clean:
	rm -f dependencies/*.js
	rm -f miniLockLib.js
	rm -f miniLockCryptoWorker.js
	
install:
	mkdir ~/.pow/minilocklib
	ln -s $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST)))) ~/.pow/minilocklib/public

uninstall:
	rm -rf ~/.pow/minilocklib
