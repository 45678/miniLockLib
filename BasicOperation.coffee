class miniLockLib.BasicOperation
  chunkSize: 1024 * 1024
  
  constructor: (params) ->
    @start() if params.start?
  
  start: (callback) =>
    @callback = callback if callback?
    if @callback is undefined
      throw "Can’t start operation without a callback."
    @startedAt = Date.now()
    @run()
  
  run: ->
    @end()
    
  end: (error, blob) =>
    @endedAt = Date.now()
    @duration = @endedAt - @startedAt
    if error
      @onerror(error)
    else
      @oncomplete(blob)
  
  onerror: (error) ->
    console.info("onerror", error)
    
  oncomplete: (blob) ->
    console.info("oncomplete", blob)
  
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
