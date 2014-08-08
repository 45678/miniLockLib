// Generated by CoffeeScript 1.7.1
(function() {
  var BasicOperation;

  BasicOperation = (function() {
    function BasicOperation() {}

    module.exports = BasicOperation;

    BasicOperation.prototype.chunkSize = 1024 * 1024;

    BasicOperation.prototype.end = function(error, blob) {
      this.endedAt = Date.now();
      this.duration = this.endedAt - this.startedAt;
      if (error) {
        return this.onerror(error);
      } else {
        return this.oncomplete(blob);
      }
    };

    BasicOperation.prototype.onerror = function(error) {
      return console.info("onerror", error);
    };

    BasicOperation.prototype.oncomplete = function(blob) {
      return console.info("oncomplete", blob);
    };

    BasicOperation.prototype.readSliceOfData = function(start, end, callback) {
      if (this.fileReader == null) {
        this.fileReader = new FileReader;
      }
      this.fileReader.readAsArrayBuffer(this.data.slice(start, end));
      this.fileReader.onabort = function(event) {
        console.error("@fileReader.onabort", event);
        return callback("File read abort.");
      };
      this.fileReader.onerror = function(event) {
        console.error("@fileReader.onerror", event);
        return callback("File read error.");
      };
      return this.fileReader.onload = function(event) {
        var sliceOfBytes;
        sliceOfBytes = new Uint8Array(event.target.result);
        return callback(void 0, sliceOfBytes);
      };
    };

    return BasicOperation;

  })();

}).call(this);
