module.exports = (start, end, callback) ->
  @fileReader ?= new FileReader
  @fileReader.readAsArrayBuffer(@data.slice(start, end))
  @fileReader.onabort = (event) ->
    console.error("@fileReader.onabort", event)
    callback "File read abort."
  @fileReader.onerror = (event) ->
    console.error("@fileReader.onerror", event)
    callback "File read error."
  @fileReader.onload = (event) ->
    sliceOfBytes = new Uint8Array(event.target.result)
    callback(undefined, sliceOfBytes)
