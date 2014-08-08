default: scripts/miniLockLib.js scripts/tests.js

scripts/miniLockLib.js: library/%.coffee library.compiled/BLAKE2s.js library.compiled/scrypt-async.js library.compiled/zxcvbn.js
	# Create a standalone copy of miniLockLib.js in the `scripts` folder.
	browserify library.compiled/index.js --standalone miniLockLib > scripts/miniLockLib.js

library/%.coffee: library.compiled
	# Compile CoffeeScript source code to Javascript and save it in `lib`.
	coffee --compile --output library.compiled library/*.coffee

library.compiled:
	# Folder for compiled library code.
	mkdir -p library.compiled

library.compiled/BLAKE2s.js:
	# Download BLAKE2s.js and modify it to export itself as a module.
	curl -s https://raw.githubusercontent.com/dchest/blake2s-js/master/blake2s.js \
	  | sed "s/var BLAKE2s = /module.exports = /" \
	  > library.compiled/BLAKE2s.js

library.compiled/scrypt-async.js:
	# Download scrypt-async.js
	curl -s https://raw.githubusercontent.com/dchest/scrypt-async-js/master/scrypt-async.js \
	  > library.compiled/scrypt-async.js

library.compiled/zxcvbn.js:
	# Make a copy of zxcvbn.js that exports itself as a module.
	cat node_modules/zxcvbn/zxcvbn.js \
	  | sed "s/window.zxcvbn=o/module.exports=o/" \
	  > library.compiled/zxcvbn.js

scripts/tests.js: tests/%.coffee
	# Create miniLockLib_tests.js in the `scripts` folder.
	browserify --debug tests.compiled/*.js > scripts/tests.js

tests/%.coffee: tests.compiled
	# Compile CoffeeScript tests to Javascript in `tests/_compiled`.
	coffee --output tests.compiled --compile tests/*.coffee

tests.compiled:
	# Folder for compiled tests.
	mkdir -p tests.compiled
	
clean:
	rm -f scripts/*.js
	rm -f library.compiled/*.js
	rm -f tests.compiled/*.js
	
install:
	# Setup POW to serve http://minilocklib.dev/tests.html
	mkdir ~/.pow/minilocklib
	ln -s $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST)))) ~/.pow/minilocklib/public

uninstall:
	# Remove POW config.
	rm -rf ~/.pow/minilocklib
