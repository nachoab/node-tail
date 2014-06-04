(() ->
  console.log "ok"
  if typeof Meteor !== 'undefined'
    require = Npm.require
  require = Npm.require

  events = require('events')
  fs = require('fs')

  environment = process.env['NODE_ENV'] || 'development'

  class _Tail extends events.EventEmitter

    readBlock:()=>
      if @queue.length >= 1
        block = @queue.shift()
        if block.end > block.start
          stream = fs.createReadStream(@filename, {start:block.start, end:block.end-1, encoding:"utf-8"})
          stream.on 'error',(error) =>
            console.log("Tail error:#{error}")
            @emit('error', error)
          stream.on 'end',=>
            @internalDispatcher.emit("next") if @queue.length >= 1
          stream.on 'data', (data) =>
            @buffer += data
            parts = @buffer.split(@separator)
            @buffer = parts.pop()
            @emit("line", chunk) for chunk in parts

    constructor:(@filename, @separator='\n', @fsWatchOptions = {}) ->
      @buffer = ''
      @internalDispatcher = new events.EventEmitter()
      @queue = []
      @isWatching = false
      stats =  fs.statSync(@filename)
      @pos = stats.size
      @internalDispatcher.on 'next',=>
        @readBlock()

      @watch()


    watch: ->
      return if @isWatching
      @isWatching = true
      if fs.watch then @watcher = fs.watch @filename, @fsWatchOptions, (e) => @watchEvent e
      else
        fs.watchFile @filename, @fsWatchOptions, (curr, prev) => @watchFileEvent curr, prev

    watchEvent:  (e) ->
      if e is 'change'
        fs.stat @filename, (err, stats) =>
          @emit 'error', err if err
          @pos = stats.size if stats.size < @pos #scenario where texts is not appended but it's actually a w+
          if stats.size > @pos
            @queue.push({start: @pos, end: stats.size})
            @pos = stats.size
            @internalDispatcher.emit("next") if @queue.length is 1
      else if e is 'rename'
        @unwatch()
        setTimeout (=> @watch()), 1000

    watchFileEvent: (curr, prev) ->
      if curr.size > prev.size
        @queue.push({start:prev.size, end:curr.size})
        @internalDispatcher.emit("next") if @queue.length is 1

    unwatch: ->
      if fs.watch && @watcher
        @watcher.close()
        @pos = 0
      else fs.unwatchFile @filename
      @isWatching = false
      @queue = []


  # Meteor
  if (typeof Package !== 'undefined') {
    Tail = _Tail;
  }
  # AMD / RequireJS
  else if (typeof define !== 'undefined' && define.amd) {
      define([], function () {
          return _Tail;
      });
  }
  # Node.js
  else if (typeof module !== 'undefined' && module.exports) {
      module.exports = _Tail;
  }
  # included directly via <script> tag
  else {
      root.async = _Tail;
  }
)();
