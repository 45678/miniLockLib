stream = require("nacl-stream").stream
NACL = require("tweetnacl")
NACL.stream = stream
module.exports = NACL
