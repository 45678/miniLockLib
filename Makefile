default: scripts/miniLockLib.js scripts/miniLockLib_tests.js scripts/tape.js

scripts/miniLockLib.js: src/%.coffee lib/BLAKE2s.js lib/scrypt-async.js lib/zxcvbn.js
	# Combine Javascript files in `lib` to create miniLockLib.js in `scripts`.
	  browserify lib/index.js --standalone miniLockLib > scripts/miniLockLib.js

src/%.coffee:
	# Compile source to Javascript in `lib`.
	coffee --compile --output lib src/*.coffee

lib/BLAKE2s.js:
	# Download BLAKE2s.js and save it in `lib`.
	curl -s https://raw.githubusercontent.com/dchest/blake2s-js/master/blake2s.js \
	  | sed "s/var BLAKE2s = /module.exports = /" \
	  > lib/BLAKE2s.js

lib/scrypt-async.js:
	# Download scrypt-async.js and save it in `lib`.
	curl -s https://raw.githubusercontent.com/dchest/scrypt-async-js/master/scrypt-async.js \
	  > lib/scrypt-async.js

lib/zxcvbn.js:
	# Make a copy of zxcvbn.js in `lib`.
	cat node_modules/zxcvbn/zxcvbn.js \
	  | sed "s/window.zxcvbn=o/module.exports=o/" \
	  > lib/zxcvbn.js

scripts/miniLockLib_tests.js: tests/%.coffee
	# Combine all the compiled Javascript tests to create miniLockLib_tests.js in `scripts`.
	browserify tests/_compiled/*.js --exclude tape > scripts/miniLockLib_tests.js

tests/%.coffee:
	# Compile CoffeeScript tests to Javascript in `tests/_compiled`.
	coffee --output tests/_compiled --compile tests/*.coffee

scripts/tape.js:
	browserify --require tape --standalone tape > scripts/tape.js
	
clean:
	rm -f lib/*.js
	rm -f scripts/*.js
	rm -f tests/_compiled/*.js
	
install:
	# Setup POW to serve http://minilocklib.dev/tests.html
	mkdir ~/.pow/minilocklib
	ln -s $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST)))) ~/.pow/minilocklib/public

uninstall:
	# Remove POW config.
	rm -rf ~/.pow/minilocklib
