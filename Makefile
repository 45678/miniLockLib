default: miniLockLib.js website/miniLockLib.js website/tests.js website/index.js website/annotated_code.js website/annotated_code

# # Library

# Create a standalone copy of miniLockLib.js at project root.
miniLockLib.js: website/miniLockLib.js
	cp website/miniLockLib.js miniLockLib.js

# Create a standalone copy of miniLockLib.js in the website folder.
website/miniLockLib.js: library/%.coffee library.compiled/scrypt-async.js library.compiled/zxcvbn.js
	browserify library.compiled/index.js --standalone miniLockLib > website/miniLockLib.js

# Compile CoffeeScript library files to the library.compiled folder.
library/%.coffee:
	mkdir -p library.compiled
	coffee --compile --output library.compiled library/*.coffee

# Download scrypt-async.js and save it in the library.compiled folder.
library.compiled/scrypt-async.js:
	curl -s https://raw.githubusercontent.com/dchest/scrypt-async-js/master/scrypt-async.js \
		> library.compiled/scrypt-async.js

# Make a copy of zxcvbn.js that exports a module instead of defining itself on `window`.
library.compiled/zxcvbn.js:
	cat node_modules/zxcvbn/zxcvbn.js \
		| sed "s/window.zxcvbn=o/module.exports=o/" \
		> library.compiled/zxcvbn.js

# # Tests

# Compile CoffeeScript tests to the tests.compiled folder.
tests/%.coffee:
	mkdir -p tests.compiled
	coffee --output tests.compiled --compile tests/*.coffee

# Make script for the test suite.
website/tests.js: tests/%.coffee
	browserify --debug tests.compiled/*.js > website/tests.js

# # Website

# Make script for website index.
website/index.js: website/index.coffee
	coffee --compile website/index.coffee

# Make script for annotated code pages.
website/annotated_code.js: website/annotated_code.coffee
	coffee --compile website/annotated_code.coffee

# Make annotated code HTML files.
website/annotated_code: library/%.coffee tests/%.coffee website/annotated_code.html.jst
	mkdir -p website/annotated_code
	docco --output website/annotated_code --template website/annotated_code.html.jst --css website/stylesheet.css library/*.coffee tests/*.coffee



# # Misc

# Remove all compiled Javascript code and annotated code pages.
clean:
	rm -f library.compiled/*.js
	rm -f tests.compiled/*.js
	rm -f website/miniLockLib.js website/tests.js website/annotated_code.js website/index.js
	rm -rf website/annotated_code

# Establish a link with [Pow](http://pow.cx/) to serve the `website` folder at `http://minilocklib.dev/`.
pow:
	mkdir -p ~/.pow/minilocklib
	ln -s $(PWD)/website ~/.pow/minilocklib/public

# Removes files added to your `~/.pow` folder by `make pow`.
unlink_pow:
	rm -rf ~/.pow/minilocklib

gh-pages:
	git checkout master
	mkdir -p gh-pages
	cp -r website/* gh-pages
	git checkout gh-pages
	rm -f *.html *.js *.css
	cp -r gh-pages/* ./
	git add --all
	git status
	git commit -m "Updated pages."
	git status
	rm -rf gh-pages
	git checkout master
