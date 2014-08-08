default: scripts/miniLockLib.js scripts/miniLockLib_tests.js scripts/tape.js

scripts/miniLockLib.js: src/%.coffee lib/BLAKE2s.js lib/scrypt-async.js lib/zxcvbn.js
	# Create a standalone copy of miniLockLib.js in the `scripts` folder.
	browserify lib/index.js --standalone miniLockLib > scripts/miniLockLib.js

src/%.coffee:
	# Compile CoffeeScript source code to Javascript and save it in `lib`.
	coffee --compile --output lib src/*.coffee

lib/BLAKE2s.js:
	# Download BLAKE2s.js and modify it to export itself as a module. Saved in `lib`.
	curl -s https://raw.githubusercontent.com/dchest/blake2s-js/master/blake2s.js \
	  | sed "s/var BLAKE2s = /module.exports = /" \
	  > lib/BLAKE2s.js

lib/scrypt-async.js:
	# Download scrypt-async.js and save it in `lib`.
	curl -s https://raw.githubusercontent.com/dchest/scrypt-async-js/master/scrypt-async.js \
	  > lib/scrypt-async.js

lib/zxcvbn.js:
	# Make a copy of zxcvbn.js in `lib` that exports itself as a module.
	cat node_modules/zxcvbn/zxcvbn.js \
	  | sed "s/window.zxcvbn=o/module.exports=o/" \
	  > lib/zxcvbn.js

scripts/tests.js: tests/%.coffee
	# Create miniLockLib_tests.js in the `scripts` folder.
	browserify tests.compiled/*.js > scripts/miniLockLib_tests.js

tests/%.coffee: tests.compiled
	# Compile CoffeeScript tests to Javascript in `tests/_compiled`.
	coffee --output tests.compiled --compile tests/*.coffee

tests.compiled:
	mkdir -p tests.compiled
	
clean:
	rm -f lib/*.js
	rm -f scripts/*.js
	rm -f tests.compiled/*.js
	
install:
	# Setup POW to serve http://minilocklib.dev/tests.html
	mkdir ~/.pow/minilocklib
	ln -s $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST)))) ~/.pow/minilocklib/public

uninstall:
	# Remove POW config.
	rm -rf ~/.pow/minilocklib
