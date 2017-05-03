HttpTransport = require("../transport/http_transport").HttpTransport
ThriftTransport = require("../transport/thrift_transport").ThriftTransport
Logger = require("../common/logger").Logger
InvokerStatistic = require("./invoker_statistic").InvokerStatistic

#Invoker为service provider的一个逻辑抽象，一个invoker对应一个provider，隐藏调用细节
class Invoker
	constructor: (config, originUrl)->
		@_executeTimeout = config.thriftProperties.executeTimeout || 5000
		@_originUrl = originUrl
		@_protocol = config.protocol
		@_initUrlObj(originUrl)
		@_index = 0
		@_statistic = new InvokerStatistic(config)

		if @_protocol is "thrift"
			@_transport = ThriftTransport
			@_clientPool = ThriftTransport.createClientPool(config, @_urlObj)
			Logger.debug("init thrift clientPool for provider:#{@_originUrl}")
		else
			@_transport = HttpTransport
			@_clientPool = HttpTransport.createClientPool(config, @_urlObj)
			Logger.debug("init http clientPool for provider:#{@_originUrl}")
		return

	_initUrlObj: (originUrl)->
		if originUrl.indexOf("\\") > 0
			throw new Error("invoker init error: provider url contains \\")
		@_urlObj = {}
		_tmp = originUrl.split(":")
		@_urlObj.host = _tmp[0]
		if _tmp.length < 2
			@_urlObj.port = 80
		else
			@_urlObj.port = _tmp[1]

	getUrl: ->
		@_originUrl

	getUrlObj: ->
		@_urlObj

	isAvailable: ->
		return @_clientPool.isAvailable()

	destroy: ->
		#@_clientPool.destroy()
		return true

	invoke: (invocation)->
		@_attach(invocation)
		@_transport.send(@_clientPool, @_urlObj, invocation)
		return

	# 增加统计和timeout配置
	_attach: (invocation)->
		self = @
		invocation.setAttachment("startTime", Date.now())
		_cb = invocation.getCallBack()
		timer = setTimeout(->
			invocation.isTimeout = true
			_timeoutError = new Error("request timeout")
			self._statistic.complete(_timeoutError, invocation)
			_cb(_timeoutError, null)
		,@_executeTimeout)

		invocation.setCallBack((err, data)->
			if not invocation.isTimeout
				clearTimeout(timer)
			self._statistic.complete(err, invocation)
			if _cb and not invocation.isTimeout
				_cb(err, data)
		)

	isUnavaliable: ->
		@_statistic.isServerUnreachable

	getStatistic: ->
		@_statistic.export()

exports.Invoker = Invoker