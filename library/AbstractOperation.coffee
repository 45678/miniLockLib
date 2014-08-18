class AbstractOperation
  module.exports = this

  chunkSize: 1024 * 1024

  end: (error, blob, attributes, header, sizeOfHeader) ->
    @endedAt = Date.now()
    @duration = @endedAt - @startedAt
    if error
      @onerror(error, header, sizeOfHeader)
    else
      @oncomplete(blob, attributes, header, sizeOfHeader)

  onerror: (error) ->
    console.info("onerror", error)

  oncomplete: (blob, attributes, header, sizeOfHeader) ->
    console.info("oncomplete", blob, attributes, header, sizeOfHeader)

  readSliceOfData: (start, end, callback) ->
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
