module.exports = class Blob
  constructor: (input, options={}) ->
    switch input?.constructor
      when undefined
        @buffer = new Buffer 0
      when Buffer
        @buffer = input
      when Number
        @buffer = new Buffer input
      when Array
        @buffer = new Buffer 0
        @buffer = Buffer.concat [@buffer, new Buffer(part)] for part in input
    @type = options.type
    @size = @buffer.length

  slice: (start, end)->
    new Blob @buffer.slice(start, end)
