// Generated by CoffeeScript 1.7.1
(function() {
  var BasicOperation, DecryptOperation, NACL, decodeBase64, encodeUTF8, _ref,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  BasicOperation = require("./BasicOperation");

  NACL = require("./NACL");

  _ref = NACL.util, encodeUTF8 = _ref.encodeUTF8, decodeBase64 = _ref.decodeBase64;

  DecryptOperation = (function(_super) {
    __extends(DecryptOperation, _super);

    module.exports = DecryptOperation;

    function DecryptOperation(params) {
      if (params == null) {
        params = {};
      }
      this.start = __bind(this.start, this);
      this.data = params.data, this.keys = params.keys, this.callback = params.callback;
      this.decryptedBytes = [];
      if (params.start != null) {
        this.start();
      }
    }

    DecryptOperation.prototype.start = function(callback) {
      var _ref1;
      if (callback != null) {
        this.callback = callback;
      }
      if (this.data === void 0) {
        throw "Can’t start miniLockLib." + this.constructor.name + " without data.";
      }
      if (((_ref1 = this.keys) != null ? _ref1.secretKey : void 0) === void 0) {
        throw "Can’t start miniLockLib." + this.constructor.name + " without keys.";
      }
      if (typeof this.callback !== "function") {
        throw "Can’t start miniLockLib." + this.constructor.name + " without a callback.";
      }
      this.startedAt = Date.now();
      return this.run();
    };

    DecryptOperation.prototype.run = function() {
      return this.decryptName((function(_this) {
        return function(error, nameWasDecrypted, startPositionOfDataBytes) {
          if (nameWasDecrypted != null) {
            return _this.decryptData(startPositionOfDataBytes, function(error, blob) {
              return _this.end(error, blob);
            });
          } else {
            return _this.end(error);
          }
        };
      })(this));
    };

    DecryptOperation.prototype.end = function(error, blob) {
      if (this.streamDecryptor != null) {
        this.streamDecryptor.clean();
      }
      return BasicOperation.prototype.end.call(this, error, blob);
    };

    DecryptOperation.prototype.oncomplete = function(blob) {
      return this.callback(void 0, {
        data: blob,
        name: this.name,
        senderID: this.permit.senderID,
        recipientID: this.permit.recipientID,
        duration: this.duration,
        startedAt: this.startedAt,
        endedAt: this.endedAt
      });
    };

    DecryptOperation.prototype.onerror = function(error) {
      return this.callback(error);
    };

    DecryptOperation.prototype.decryptName = function(callback) {
      return this.constructStreamDecryptor((function(_this) {
        return function(error, lengthOfHeader) {
          var endPosition, startPosition;
          if (error) {
            return callback(error);
          }
          startPosition = 12 + lengthOfHeader;
          endPosition = 12 + lengthOfHeader + 256 + 4 + 16;
          return _this.readSliceOfData(startPosition, endPosition, function(error, sliceOfBytes) {
            var byte, fixedLengthNameAsBytes, nameAsBytes;
            if (error) {
              return callback(error);
            }
            fixedLengthNameAsBytes = _this.streamDecryptor.decryptChunk(sliceOfBytes, false);
            if (fixedLengthNameAsBytes) {
              nameAsBytes = (function() {
                var _i, _len, _results;
                _results = [];
                for (_i = 0, _len = fixedLengthNameAsBytes.length; _i < _len; _i++) {
                  byte = fixedLengthNameAsBytes[_i];
                  if (byte !== 0) {
                    _results.push(byte);
                  }
                }
                return _results;
              })();
              _this.name = encodeUTF8(nameAsBytes);
              return callback(void 0, _this.name != null, endPosition);
            } else {
              return callback("DecryptOperation failed to decrypt file name.");
            }
          });
        };
      })(this));
    };

    DecryptOperation.prototype.decryptData = function(position, callback) {
      return this.constructStreamDecryptor((function(_this) {
        return function(error, lengthOfHeader) {
          var endPosition, startPosition;
          if (error) {
            return callback(error);
          }
          startPosition = position;
          endPosition = position + _this.chunkSize + 4 + 16;
          return _this.readSliceOfData(startPosition, endPosition, function(error, sliceOfBytes) {
            var decryptedBytes, isLast;
            isLast = position + sliceOfBytes.length === _this.data.size;
            decryptedBytes = _this.streamDecryptor.decryptChunk(sliceOfBytes, isLast);
            if (decryptedBytes) {
              _this.decryptedBytes.push(decryptedBytes);
              if (isLast) {
                return callback(void 0, new Blob(_this.decryptedBytes));
              } else {
                return _this.decryptData(endPosition, callback);
              }
            } else {
              return callback("DecryptOperation failed to decrypt file data.");
            }
          });
        };
      })(this));
    };

    DecryptOperation.prototype.constructStreamDecryptor = function(callback) {
      return this.decryptUniqueNonceAndPermit((function(_this) {
        return function(error, uniqueNonce, permit, lengthOfHeader) {
          if (uniqueNonce && permit && lengthOfHeader) {
            _this.uniqueNonce = uniqueNonce;
            _this.permit = permit;
            _this.fileKey = permit.fileInfo.fileKey;
            _this.fileNonce = permit.fileInfo.fileNonce;
            _this.streamDecryptor = NACL.stream.createDecryptor(_this.fileKey, _this.fileNonce, _this.chunkSize);
            _this.constructStreamDecryptor = function(callback) {
              return callback(void 0, lengthOfHeader);
            };
            return _this.constructStreamDecryptor(callback);
          } else {
            return callback(error);
          }
        };
      })(this));
    };

    DecryptOperation.prototype.decryptUniqueNonceAndPermit = function(callback) {
      return this.readHeader((function(_this) {
        return function(error, header, lengthOfHeader) {
          var permit, returned, uniqueNonce;
          if (error) {
            return callback(error);
          } else {
            returned = _this.findUniqueNonceAndPermit(header);
            if (returned) {
              uniqueNonce = returned[0], permit = returned[1];
              return callback(void 0, uniqueNonce, permit, lengthOfHeader);
            } else {
              return callback("File is not encrypted for this recipient");
            }
          }
        };
      })(this));
    };

    DecryptOperation.prototype.findUniqueNonceAndPermit = function(header) {
      var decodedEncryptedPermit, encodedEncryptedPermit, encodedUniqueNonce, ephemeral, permit, uniqueNonce, _ref1;
      ephemeral = decodeBase64(header.ephemeral);
      _ref1 = header.decryptInfo;
      for (encodedUniqueNonce in _ref1) {
        encodedEncryptedPermit = _ref1[encodedUniqueNonce];
        uniqueNonce = decodeBase64(encodedUniqueNonce);
        decodedEncryptedPermit = decodeBase64(encodedEncryptedPermit);
        permit = this.decryptPermit(decodedEncryptedPermit, uniqueNonce, ephemeral);
        if (permit) {
          return [uniqueNonce, permit];
        }
      }
      return void 0;
    };

    DecryptOperation.prototype.decryptPermit = function(decodedEncryptedPermit, uniqueNonce, ephemeral) {
      var decodedEncryptedFileInfo, decryptedPermit, decryptedPermitAsBytes, decryptedPermitAsString, senderPublicKey;
      decryptedPermitAsBytes = NACL.box.open(decodedEncryptedPermit, uniqueNonce, ephemeral, this.keys.secretKey);
      if (decryptedPermitAsBytes) {
        decryptedPermitAsString = encodeUTF8(decryptedPermitAsBytes);
        decryptedPermit = JSON.parse(decryptedPermitAsString);
        decodedEncryptedFileInfo = decodeBase64(decryptedPermit.fileInfo);
        senderPublicKey = miniLockLib.ID.decode(decryptedPermit.senderID);
        decryptedPermit.fileInfo = this.decryptFileInfo(decodedEncryptedFileInfo, uniqueNonce, senderPublicKey);
        return decryptedPermit;
      } else {
        return void 0;
      }
    };

    DecryptOperation.prototype.decryptFileInfo = function(decodedEncryptedFileInfo, uniqueNonce, senderPublicKey) {
      var decryptedFileInfo, decryptedFileInfoAsBytes, decryptedFileInfoAsString;
      decryptedFileInfoAsBytes = NACL.box.open(decodedEncryptedFileInfo, uniqueNonce, senderPublicKey, this.keys.secretKey);
      if (decryptedFileInfoAsBytes) {
        decryptedFileInfoAsString = encodeUTF8(decryptedFileInfoAsBytes);
        decryptedFileInfo = JSON.parse(decryptedFileInfoAsString);
        return {
          fileHash: decryptedFileInfo.fileHash,
          fileKey: decodeBase64(decryptedFileInfo.fileKey),
          fileNonce: decodeBase64(decryptedFileInfo.fileNonce)
        };
        return decryptedFileInfo;
      } else {
        return void 0;
      }
    };

    DecryptOperation.prototype.readHeader = function(callback) {
      return this.readLengthOfHeader((function(_this) {
        return function(error, lengthOfHeader) {
          if (error) {
            return callback(error);
          }
          return _this.readSliceOfData(12, lengthOfHeader + 12, function(error, sliceOfBytes) {
            var header, headerAsString;
            if (error) {
              return callback(error);
            }
            headerAsString = encodeUTF8(sliceOfBytes);
            header = JSON.parse(headerAsString);
            return callback(void 0, header, lengthOfHeader);
          });
        };
      })(this));
    };

    DecryptOperation.prototype.readLengthOfHeader = function(callback) {
      return this.readSliceOfData(8, 12, (function(_this) {
        return function(error, sliceOfBytes) {
          var lengthOfHeader;
          if (error) {
            return callback(error);
          }
          lengthOfHeader = miniLockLib.byteArrayToNumber(sliceOfBytes);
          return callback(void 0, lengthOfHeader);
        };
      })(this));
    };

    return DecryptOperation;

  })(BasicOperation);

}).call(this);