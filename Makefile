default: website/miniLockLib.js website/tests.js website/index.js website/annotated_code.js website/annotated_code .window_tests_address

# Create a standalone copy of miniLockLib.js in the website folder for use in web agent windows.
website/miniLockLib.js: library/%.coffee
	browserify library.compiled/index.js --standalone miniLockLib > website/miniLockLib.js

# Compile CoffeeScript library files to the library.compiled folder.
library/%.coffee:
	coffee --compile --output library.compiled library/*.coffee

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
	rm website/annotated_code/stylesheet.css

# # Misc

# Remove all compiled Javascript code and annotated code pages.
clean:
	rm -f miniLockLib.js
	rm -f library.compiled/*.js
	rm -f tests.compiled/*.js
	rm -f website/miniLockLib.js website/tests.js website/annotated_code.js website/index.js
	rm -rf website/annotated_code

# Make default config file for the address of the test window.
.window_tests_address:
	echo "http://localhost:45678/tests.html" >> .window_tests_address

# Establish a link with [Pow](http://pow.cx/) to serve the `website` folder at `http://minilocklib.dev/`.
pow:
	mkdir -p ~/.pow/minilocklib
	ln -s $(PWD)/website ~/.pow/minilocklib/public

# Removes files added to your `~/.pow` folder by `make pow`.
unlink_pow:
	rm -rf ~/.pow/minilocklib

gh-pages: website/miniLockLib.js website/tests.js website/index.js website/annotated_code.js website/annotated_code
	git checkout master
	rm -rf gh-pages
	mkdir gh-pages
	cp website/*.css gh-pages
	cp website/*.js gh-pages
	cp website/*.html gh-pages
	cp website/*.png gh-pages
	cp -r website/annotated_code gh-pages
	git checkout gh-pages
	rm -f *.html *.js *.css *.png
	cp -r gh-pages/* ./
	git add --all
	git commit --message "Commited with make gh-pages"
	git push origin gh-pages
	rm -rf gh-pages
	git checkout master
