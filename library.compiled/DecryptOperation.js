// Generated by CoffeeScript 1.10.0
(function() {
  var DecryptOperation,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  module.exports = DecryptOperation = (function() {
    var Blob, ID, NaCl, byteArrayToNumber, decodeBase64, encodeUTF8, ref;

    NaCl = require("tweetnacl");

    NaCl.stream = require("nacl-stream").stream;

    ref = NaCl.util, encodeUTF8 = ref.encodeUTF8, decodeBase64 = ref.decodeBase64;

    ID = require("./ID");

    byteArrayToNumber = require("./util").byteArrayToNumber;

    Blob = (typeof window !== "undefined" && window !== null ? window.Blob : void 0) || require("./Blob");

    DecryptOperation.prototype.chunkSize = 1024 * 1024;

    DecryptOperation.prototype.readSliceOfData = require("./readSliceOfData");

    function DecryptOperation(params) {
      if (params == null) {
        params = {};
      }
      this.start = bind(this.start, this);
      this.data = params.data, this.keys = params.keys, this.callback = params.callback;
      this.decryptedBytes = [];
      if (params.start != null) {
        this.start();
      }
    }

    DecryptOperation.prototype.start = function(callback) {
      var ref1, ref2;
      if (callback != null) {
        this.callback = callback;
      }
      if (((ref1 = this.callback) != null ? ref1.constructor : void 0) !== Function) {
        throw "Can’t start decrypt operation without a callback function.";
      }
      switch (false) {
        case this.data !== void 0:
          this.callback("Can’t decrypt without a Blob of data.");
          break;
        case ((ref2 = this.keys) != null ? ref2.secretKey : void 0) !== void 0:
          this.callback("Can’t decrypt without a set of keys.");
          break;
        default:
          this.startedAt = Date.now();
          this.run();
      }
      return this;
    };

    DecryptOperation.prototype.run = function() {
      return this.readHeader((function(_this) {
        return function(error, header, sizeOfHeader) {
          return _this["decryptVersion" + header.version + "Attributes"](function(error, attributes, startOfEncryptedDataBytes) {
            if (error === void 0) {
              return _this.decryptData(startOfEncryptedDataBytes, function(error, blob) {
                return _this.end(error, blob, attributes, header, sizeOfHeader);
              });
            } else {
              return _this.end(error, void 0, attributes, header, sizeOfHeader);
            }
          });
        };
      })(this));
    };

    DecryptOperation.prototype.end = function(error, blob, attributes, header, sizeOfHeader) {
      if (this.streamDecryptor != null) {
        this.streamDecryptor.clean();
      }
      this.endedAt = Date.now();
      this.duration = this.endedAt - this.startedAt;
      if (error) {
        return this.onerror(error, header, sizeOfHeader);
      } else {
        return this.oncomplete(blob, attributes, header, sizeOfHeader);
      }
    };

    DecryptOperation.prototype.oncomplete = function(blob, attributes, header, sizeOfHeader) {
      return this.callback(void 0, {
        data: blob,
        name: attributes.name,
        type: attributes.type,
        time: attributes.time,
        senderID: this.permit.senderID,
        recipientID: this.permit.recipientID,
        fileKey: this.permit.fileInfo.fileKey,
        fileNonce: this.permit.fileInfo.fileNonce,
        fileHash: this.permit.fileInfo.fileHash,
        duration: this.duration,
        startedAt: this.startedAt,
        endedAt: this.endedAt
      }, header, sizeOfHeader);
    };

    DecryptOperation.prototype.onerror = function(error, header, sizeOfHeader) {
      return this.callback(error, void 0, header, sizeOfHeader);
    };

    DecryptOperation.prototype.decryptVersion1Attributes = function(callback) {
      return this.constructMap((function(_this) {
        return function(error, map) {
          if (error) {
            return callback(error);
          }
          return _this.constructStreamDecryptor(function(error) {
            var ciphertextBytes, end, start;
            if (error) {
              return callback(error);
            }
            ciphertextBytes = map.ciphertextBytes;
            start = ciphertextBytes.start;
            end = ciphertextBytes.start + 256 + 4 + 16;
            return _this.readSliceOfData(start, end, function(error, sliceOfBytes) {
              var attributes, byte, decryptedBytes, nameAsBytes;
              if (error) {
                return callback(error);
              }
              if (decryptedBytes = _this.streamDecryptor.decryptChunk(sliceOfBytes, false)) {
                nameAsBytes = (function() {
                  var i, len, results;
                  results = [];
                  for (i = 0, len = decryptedBytes.length; i < len; i++) {
                    byte = decryptedBytes[i];
                    if (byte !== 0) {
                      results.push(byte);
                    }
                  }
                  return results;
                })();
                attributes = {
                  name: encodeUTF8(nameAsBytes)
                };
                return callback(void 0, attributes, end);
              } else {
                return callback("Failed to decrypt version 1 file attributes.");
              }
            });
          });
        };
      })(this));
    };

    DecryptOperation.prototype.decryptVersion2Attributes = function(callback) {
      return this.constructMap((function(_this) {
        return function(error, map) {
          if (error) {
            return callback(error);
          }
          return _this.constructStreamDecryptor(function(error) {
            var ciphertextBytes, end, start;
            if (error) {
              return callback(error);
            }
            ciphertextBytes = map.ciphertextBytes;
            start = ciphertextBytes.start;
            end = ciphertextBytes.start + 256 + 128 + 24 + 4 + 16;
            return _this.readSliceOfData(start, end, function(error, sliceOfBytes) {
              var attributes, byte, decryptedBytes, decryptedNameBytes, decryptedTimeBytes, decryptedTypeBytes, nameAsBytes, timeAsBytes, typeAsBytes;
              if (error) {
                return callback(error);
              }
              if (decryptedBytes = _this.streamDecryptor.decryptChunk(sliceOfBytes, false)) {
                decryptedNameBytes = decryptedBytes.subarray(0, 256);
                nameAsBytes = (function() {
                  var i, len, results;
                  results = [];
                  for (i = 0, len = decryptedNameBytes.length; i < len; i++) {
                    byte = decryptedNameBytes[i];
                    if (byte !== 0) {
                      results.push(byte);
                    }
                  }
                  return results;
                })();
                decryptedTypeBytes = decryptedBytes.subarray(256, 256 + 128);
                typeAsBytes = (function() {
                  var i, len, results;
                  results = [];
                  for (i = 0, len = decryptedTypeBytes.length; i < len; i++) {
                    byte = decryptedTypeBytes[i];
                    if (byte !== 0) {
                      results.push(byte);
                    }
                  }
                  return results;
                })();
                decryptedTimeBytes = decryptedBytes.subarray(256 + 128, 256 + 128 + 24);
                timeAsBytes = (function() {
                  var i, len, results;
                  results = [];
                  for (i = 0, len = decryptedTimeBytes.length; i < len; i++) {
                    byte = decryptedTimeBytes[i];
                    if (byte !== 0) {
                      results.push(byte);
                    }
                  }
                  return results;
                })();
                attributes = {
                  name: encodeUTF8(nameAsBytes),
                  type: encodeUTF8(typeAsBytes),
                  time: encodeUTF8(timeAsBytes)
                };
                return callback(void 0, attributes, end);
              } else {
                return callback("Failed to decrypt version 2 file attributes.");
              }
            });
          });
        };
      })(this));
    };

    DecryptOperation.prototype.decryptData = function(position, callback) {
      return this.constructStreamDecryptor((function(_this) {
        return function(error) {
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
              return callback("Failed to decrypt slice of data at [" + startPosition + ".." + endPosition + "]");
            }
          });
        };
      })(this));
    };

    DecryptOperation.prototype.constructMap = function(callback) {
      return this.readHeader((function(_this) {
        return function(error, header, sizeOfHeader) {
          var ciphertextBytes, headerBytes, magicBytes, sizeOfHeaderBytes;
          if ((error === void 0) && (sizeOfHeader != null)) {
            magicBytes = {
              start: 0,
              end: 8
            };
            sizeOfHeaderBytes = {
              start: 8,
              end: 12
            };
            headerBytes = {
              start: 12,
              end: 12 + sizeOfHeader
            };
            ciphertextBytes = {
              start: headerBytes.end,
              end: _this.data.size
            };
          }
          return callback(error, {
            magicBytes: magicBytes,
            sizeOfHeaderBytes: sizeOfHeaderBytes,
            headerBytes: headerBytes,
            ciphertextBytes: ciphertextBytes
          });
        };
      })(this));
    };

    DecryptOperation.prototype.constructStreamDecryptor = function(callback) {
      return this.decryptUniqueNonceAndPermit((function(_this) {
        return function(error, uniqueNonce, permit) {
          if (uniqueNonce && permit) {
            _this.uniqueNonce = uniqueNonce;
            _this.permit = permit;
            _this.fileKey = permit.fileInfo.fileKey;
            _this.fileNonce = permit.fileInfo.fileNonce;
            _this.streamDecryptor = NaCl.stream.createDecryptor(_this.fileKey, _this.fileNonce, _this.chunkSize);
            _this.constructStreamDecryptor = function(callback) {
              return callback(void 0);
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
        return function(error, header) {
          var permit, returned, uniqueNonce;
          if (error) {
            return callback(error);
          } else {
            returned = _this.findUniqueNonceAndPermit(header);
            if (returned) {
              uniqueNonce = returned[0], permit = returned[1];
              return callback(void 0, uniqueNonce, permit);
            } else {
              return callback("Can’t decrypt this file with this set of keys.");
            }
          }
        };
      })(this));
    };

    DecryptOperation.prototype.findUniqueNonceAndPermit = function(header) {
      var decodedEncryptedPermit, encodedEncryptedPermit, encodedUniqueNonce, ephemeral, permit, ref1, uniqueNonce;
      ephemeral = decodeBase64(header.ephemeral);
      ref1 = header.decryptInfo;
      for (encodedUniqueNonce in ref1) {
        encodedEncryptedPermit = ref1[encodedUniqueNonce];
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
      decryptedPermitAsBytes = NaCl.box.open(decodedEncryptedPermit, uniqueNonce, ephemeral, this.keys.secretKey);
      if (decryptedPermitAsBytes) {
        decryptedPermitAsString = encodeUTF8(decryptedPermitAsBytes);
        decryptedPermit = JSON.parse(decryptedPermitAsString);
        decodedEncryptedFileInfo = decodeBase64(decryptedPermit.fileInfo);
        senderPublicKey = ID.decode(decryptedPermit.senderID);
        decryptedPermit.fileInfo = this.decryptFileInfo(decodedEncryptedFileInfo, uniqueNonce, senderPublicKey);
        return decryptedPermit;
      } else {
        return void 0;
      }
    };

    DecryptOperation.prototype.decryptFileInfo = function(decodedEncryptedFileInfo, uniqueNonce, senderPublicKey) {
      var decryptedFileInfo, decryptedFileInfoAsBytes, decryptedFileInfoAsString;
      decryptedFileInfoAsBytes = NaCl.box.open(decodedEncryptedFileInfo, uniqueNonce, senderPublicKey, this.keys.secretKey);
      if (decryptedFileInfoAsBytes) {
        decryptedFileInfoAsString = encodeUTF8(decryptedFileInfoAsBytes);
        decryptedFileInfo = JSON.parse(decryptedFileInfoAsString);
        return {
          fileHash: decodeBase64(decryptedFileInfo.fileHash),
          fileKey: decodeBase64(decryptedFileInfo.fileKey),
          fileNonce: decodeBase64(decryptedFileInfo.fileNonce)
        };
      } else {
        return void 0;
      }
    };

    DecryptOperation.prototype.readHeader = function(callback) {
      return this.readSizeOfHeader((function(_this) {
        return function(error, sizeOfHeader) {
          if (error) {
            return callback(error);
          }
          return _this.readSliceOfData(12, 12 + sizeOfHeader, function(error, sliceOfBytes) {
            var header, headerAsString;
            if (error) {
              return callback(error);
            }
            headerAsString = encodeUTF8(sliceOfBytes);
            header = JSON.parse(headerAsString);
            return callback(void 0, header, sizeOfHeader);
          });
        };
      })(this));
    };

    DecryptOperation.prototype.readSizeOfHeader = function(callback) {
      return this.readSliceOfData(8, 12, (function(_this) {
        return function(error, sliceOfBytes) {
          var sizeOfHeader;
          if (error) {
            return callback(error);
          }
          sizeOfHeader = byteArrayToNumber(sliceOfBytes);
          return callback(error, sizeOfHeader);
        };
      })(this));
    };

    return DecryptOperation;

  })();

}).call(this);
