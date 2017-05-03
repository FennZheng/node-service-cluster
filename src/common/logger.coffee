require("./../util/date.js")

class Logger
	constructor : ->
		@_logger = null
		@_hasLogger = false
		@isDebugEnable = false

	init : (logger)->
		if not logger
			console.log("node-service-cluster use console.log instead, cause by: logger is null")
			return
		@_logger = logger
		@_hasLogger = true
		@isDebugEnable = logger.isDebugEnable?()

	debug : (msg)->
		if @_hasLogger
			@_logger.debug(msg)
		else
			console.log("[#{@_getTime()}][node-service-cluster][DEBUG] #{msg}") if @isDebugEnable

	info : (msg)->
		if @_hasLogger
			@_logger.info(msg)
		else
			console.log("[#{@_getTime()}][node-service-cluster][INFO] #{msg}")

	error : (msg)->
		if @_hasLogger
			@_logger.error(msg)
		else
			console.error("[#{@_getTime()}][node-service-cluster][ERROR] #{msg}")

	_getTime : ->
		new Date().format("yyyy-MM-dd HH:mm:ss.S")

_instance = new Logger()

init = (logger)->
	_instance.init(logger)

exports.Logger = _instance
exports.init = init