// Generated by CoffeeScript 1.10.0
(function() {
  var Alice, Bobby, miniLockLib, read, readFromNetwork, ref, ref1, tape;

  ref = require("./test_setup"), tape = ref.tape, miniLockLib = ref.miniLockLib;

  ref1 = require("./fixtures"), Alice = ref1.Alice, Bobby = ref1.Bobby, read = ref1.read, readFromNetwork = ref1.readFromNetwork;

  tape("Identification", function(test) {
    return test.end();
  });

  tape("Decode public key from Alice’s ID", function(test) {
    var publicKey;
    publicKey = miniLockLib.ID.decode(Alice.miniLockID);
    test.same(publicKey, Alice.publicKey);
    return test.end();
  });

  tape("Decode public key from Bobby’s ID", function(test) {
    var publicKey;
    publicKey = miniLockLib.ID.decode(Bobby.miniLockID);
    test.same(publicKey, Bobby.publicKey);
    return test.end();
  });

  tape("Make ID for Alice’s public key", function(test) {
    var miniLockID;
    miniLockID = miniLockLib.ID.encode(Alice.publicKey);
    test.same(miniLockID, Alice.miniLockID);
    return test.end();
  });

  tape("Make ID for Bobby’s public key", function(test) {
    var miniLockID;
    miniLockID = miniLockLib.ID.encode(Alice.publicKey);
    test.same(miniLockID, Alice.miniLockID);
    return test.end();
  });

  tape("Can’t make ID for undefined key", function(test) {
    var miniLockID;
    miniLockID = miniLockLib.ID.encode(undefined);
    test.same(miniLockID, undefined);
    return test.end();
  });

  tape("Can’t make ID for key that is too short", function(test) {
    var miniLockID;
    miniLockID = miniLockLib.ID.encode(new Uint8Array(16));
    test.same(miniLockID, undefined);
    return test.end();
  });

  tape("Can’t make ID for key that is too long", function(test) {
    var miniLockID;
    miniLockID = miniLockLib.ID.encode(new Uint8Array(64));
    test.same(miniLockID, undefined);
    return test.end();
  });

}).call(this);
