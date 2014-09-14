stream = require("nacl-stream").stream
NaCl = require("tweetnacl")
NaCl.stream = stream
module.exports = NaCl
