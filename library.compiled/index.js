// Generated by CoffeeScript 1.7.1
(function() {
  var BLAKE2, BLAKE2HashDigest, Base58, EmailAddressPattern, NACL, calculateCurve25519Keys, miniLockLib, scrypt, zxcvbn;

  miniLockLib = module.exports = {};

  miniLockLib.NACL = NACL = require("./NACL");

  miniLockLib.scrypt = scrypt = require("./scrypt-async");

  miniLockLib.zxcvbn = zxcvbn = require("./zxcvbn");

  miniLockLib.ID = require("./ID");

  miniLockLib.EncryptOperation = require("./EncryptOperation");

  miniLockLib.DecryptOperation = require("./DecryptOperation");

  miniLockLib.Base58 = Base58 = require("./Base58");

  miniLockLib.BLAKE2 = BLAKE2 = require("./BLAKE2s");

  miniLockLib.secretPhraseIsAcceptable = function(secretPhrase) {
    return (secretPhrase != null ? secretPhrase.length : void 0) >= 32 && zxcvbn(secretPhrase).entropy >= 100;
  };

  miniLockLib.emailAddressIsAcceptable = function(emailAddress) {
    return EmailAddressPattern.test(emailAddress);
  };

  EmailAddressPattern = /[-0-9A-Z.+_]+@[-0-9A-Z.+_]+\.[A-Z]{2,20}/i;

  miniLockLib.getKeyPair = function(secretPhrase, emailAddress, callback) {
    var decodedEmailAddress, decodedSecretPhrase, hashOfDecodedSecretPhrase;
    decodedSecretPhrase = NACL.util.decodeUTF8(secretPhrase);
    decodedEmailAddress = NACL.util.decodeUTF8(emailAddress);
    hashOfDecodedSecretPhrase = BLAKE2HashDigest(decodedSecretPhrase, {
      length: 32
    });
    return calculateCurve25519Keys(hashOfDecodedSecretPhrase, decodedEmailAddress, callback);
  };

  calculateCurve25519Keys = function(secret, salt, callback) {
    var dkLen, encoding, interruptStep, logN, r, whenKeysAreReady;
    whenKeysAreReady = function(encodedBytes) {
      var decodedBytes, keys;
      decodedBytes = NACL.util.decodeBase64(encodedBytes);
      keys = NACL.box.keyPair.fromSecretKey(decodedBytes);
      return callback(keys);
    };
    logN = 17;
    r = 8;
    dkLen = 32;
    interruptStep = 1000;
    encoding = "base64";
    return scrypt(secret, salt, logN, r, dkLen, interruptStep, whenKeysAreReady, encoding);
  };

  miniLockLib.encrypt = function(params) {
    var callback, data, keys, miniLockIDs, name;
    data = params.data, name = params.name, miniLockIDs = params.miniLockIDs, keys = params.keys, callback = params.callback;
    return new miniLockLib.EncryptOperation({
      data: data,
      name: name,
      keys: keys,
      miniLockIDs: miniLockIDs,
      saveName: name + ".minilock",
      callback: callback,
      start: true
    });
  };

  miniLockLib.decrypt = function(params) {
    var callback, data, keys;
    data = params.data, keys = params.keys, callback = params.callback;
    return new miniLockLib.DecryptOperation({
      data: data,
      keys: keys,
      callback: callback,
      start: true
    });
  };

  miniLockLib.ErrorMessages = {
    1: "General encryption error",
    2: "General decryption error",
    3: "Could not parse header",
    4: "Invalid header version",
    5: "Could not validate sender ID",
    6: "File is not encrypted for this recipient",
    7: "Could not validate ciphertext hash"
  };

  BLAKE2HashDigest = function(input, options) {
    var hash;
    if (options == null) {
      options = {};
    }
    hash = new BLAKE2(options.length);
    hash.update(input);
    return hash.digest();
  };

}).call(this);
