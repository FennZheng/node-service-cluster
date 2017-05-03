RegistryDirectory = require("./registry_directory").RegistryDirectory
LoadBalance = require("../load_balance")
UUID = require("node-uuid")
Logger = require("../common/logger").Logger
ERROR = require("../common/constants").ERROR

#ClusterInvoker将一组invoker看成一个服务
class ClusterInvoker
	constructor: (config, serviceBundles)->
		@_clusterId = config.serviceId + UUID.v1()
		@_loadBalanceRef = LoadBalance.getLoadBalance(config.balance)
		@_directory = new RegistryDirectory(config, serviceBundles)
		@_inited = false
		return

	init: (cb)->
		return cb(new Error(ERROR.REPEAT_INITED), false) if @_inited
		@_inited = true
		@_directory.init(cb)
		return

	invoke: (invocation)->
		_invokers = @_directory.list()
		if not _invokers or _invokers.length < 1
			@_procedureError(invocation, ERROR.NO_AVAILABLE_INVOKER)

		_selectInvoker = null
		i = 0
		while i++ < _invokers.length
			_selectInvoker = @_loadBalanceRef.select(@_clusterId, _invokers, invocation)
			if _selectInvoker
				if _selectInvoker.isUnavaliable()
					@_directory.removeInvoker(_selectInvoker)
				else
					break;
			else
				break;
		if _selectInvoker
			_selectInvoker.invoke(invocation)
		else
			@_procedureError(invocation, ERROR.NO_AVAILABLE_INVOKER)
		return

	getStatistic: ->
		_clusterStatistic = {}
		_invokers = @_directory.list()
		if not _invokers or _invokers.length < 1
			return {}
		for _invoker in _invokers
			_clusterStatistic[_invoker.getUrl()] = _invoker.getStatistic()
		return _clusterStatistic

	_procedureError: (invocation, errorMsg)->
		_cb = invocation.getCallBack()
		if _cb
			return _cb(new Error(errorMsg))
		else
			return throw new Error(errorMsg)

exports.ClusterInvoker = ClusterInvoker
