if root?.process?.argv?
  exports.tape = require("tape")
  exports.miniLockLib = require("..")
else
  exports.tape = require("./window_test_harness")
  exports.miniLockLib = window.miniLockLib
