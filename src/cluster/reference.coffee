ClusterInvoker = require("./cluster_invoker").ClusterInvoker
ConfigValidator = require("./../common/config_validator")
Invocation = require("./invocation").Invocation
ERROR = require("../common/constants").ERROR

#provider的代理
class Reference
	constructor: (config, serviceBundles)->
		_errorMsg = ConfigValidator.validate(config)
		if _errorMsg
			throw new Error(_errorMsg)
		@_name = config.name
		@_statistic = {}
		@_clusterInvoker = new ClusterInvoker(config, serviceBundles)
		@_inited = false
		@_initTimeout = config.initTimeout || 5000
		@_isAlreadyTimeout = false
		return

	init : (cb)->
		return cb(new Error(ERROR.REPEAT_INITED), false) if @_inited
		@_inited = true
		self = @
		timer = setTimeout(->
			self._isAlreadyTimeout = true
			cb(new Error(ERROR.INIT_TIMEOUT+"(#{self._initTimeout}ms) maybe unable to get service provider urls"), false)
		,@_initTimeout)

		@_clusterInvoker.init((err, result)->
			clearTimeout(timer) if not self._isAlreadyTimeout
			cb(err, result)
		)
		return

	invoke: (invocation)->
		return if not @_inited
		_errorMsg = Invocation.validate(invocation)
		_cb = invocation.getCallBack()
		if _errorMsg
			return cb(new Error(_errorMsg)) if _cb
			return throw new Error(_errorMsg)

		if @_clusterInvoker
			@_clusterInvoker.invoke(invocation)
		return

	getStatistic: ->
		@_clusterInvoker.getStatistic()

exports.Reference = Reference

#写测试代码，对业务场景进行细化
#在写央视
#明天：Reference的外部初始化要完成。
#怎样划分业务来引用不同的reference，会有什么问题吗？监听东西太多的话？？？某些概念比如registery应该单利，