// Generated by CoffeeScript 1.10.0
(function() {
  var KeyPairOperation;

  module.exports = KeyPairOperation = (function() {
    var BLAKE2s, EmailAddress, NaCl, SecretPhrase, calculateCurve25519KeyPair, scrypt;

    BLAKE2s = require("./BLAKE2s");

    NaCl = require("tweetnacl");

    scrypt = require("./scrypt-async");

    EmailAddress = require("./EmailAddress");

    SecretPhrase = require("./SecretPhrase");

    function KeyPairOperation(params) {
      this.secretPhrase = params.secretPhrase, this.emailAddress = params.emailAddress;
    }

    KeyPairOperation.prototype.secret = function() {
      return NaCl.util.decodeUTF8(this.secretPhrase);
    };

    KeyPairOperation.prototype.salt = function() {
      return NaCl.util.decodeUTF8(this.emailAddress);
    };

    KeyPairOperation.prototype.hashDigestOfSecret = function() {
      return (new BLAKE2s({
        length: 32
      })).update(this.secret()).digest();
    };

    KeyPairOperation.prototype.start = function(callback) {
      if ((callback != null ? callback.constructor : void 0) !== Function) {
        throw "Can’t make keys without a callback function.";
      }
      if (this.secretPhrase === void 0) {
        callback("Can’t make keys without a secret phrase.");
        return false;
      }
      if (SecretPhrase.isAcceptable(this.secretPhrase) === false) {
        callback("Can’t make keys because '" + this.secretPhrase + "' is not an acceptable secret phrase.");
        return false;
      }
      if (this.emailAddress === void 0) {
        callback("Can’t make keys without an email address.");
        return false;
      }
      if (EmailAddress.isAcceptable(this.emailAddress) === false) {
        callback("Can’t make keys because '" + this.emailAddress + "' is not an acceptable email address.");
        return false;
      }
      if (this.secretPhrase && this.emailAddress && callback) {
        calculateCurve25519KeyPair(this.hashDigestOfSecret(), this.salt(), function(keys) {
          return callback(void 0, keys);
        });
        return this;
      }
    };

    calculateCurve25519KeyPair = function(secret, salt, callback) {
      var dkLen, encoding, interruptStep, logN, r, whenKeysAreReady;
      whenKeysAreReady = function(encodedBytes) {
        var decodedBytes, keys;
        decodedBytes = NaCl.util.decodeBase64(encodedBytes);
        keys = NaCl.box.keyPair.fromSecretKey(decodedBytes);
        return callback(keys);
      };
      logN = 17;
      r = 8;
      dkLen = 32;
      interruptStep = 1000;
      encoding = "base64";
      return scrypt(secret, salt, logN, r, dkLen, interruptStep, whenKeysAreReady, encoding);
    };

    return KeyPairOperation;

  })();

}).call(this);
