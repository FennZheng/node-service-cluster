Events = require("events")
Constants = require("../common/constants").Constants
ZookeeperRegistry = require("../registry/zookeeper_registry").ZookeeperRegistry
LocalRegistry = require("../registry/local_registry").LocalRegistry
Invoker = require("./invoker").Invoker
Logger = require("../common/logger").Logger
ERROR = require("../common/constants").ERROR
URL_REGEX = new RegExp("((http|ftp|https)://)\
(([a-zA-Z0-9\._-]+\.[a-zA-Z]{2,6})|([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}))(:[0-9]{1,4})*(/[a-zA-Z0-9\&%_\./-~-]*)?")
MERGE_TYPE_INCREMENT = "increment"
MERGE_TYPE_COMPLETE = "complete"

#一组节点，向registry订阅变更,https://en.wikipedia.org/wiki/Directory_service
class RegistryDirectory
	constructor: (config, serviceBundles)->
		#init a registry implementation dependent by whether config.registry match url regex
		if URL_REGEX.test(config.registry)
			@_registry = new ZookeeperRegistry(config, serviceBundles)
			@_mergeType = MERGE_TYPE_COMPLETE
		else
			@_registry = new LocalRegistry(config)
			@_mergeType = MERGE_TYPE_INCREMENT
		@_groupId = config.groupId
		@_serviceId= config.serviceId
		@_directoryUrl = null
		#@_invokers = []
		@_invokerSet = {}
		@_configRef = config
		@_inited = false
		return

	init: (cb)->
		return cb(new Error(ERROR.REPEAT_INITED), false) if @_inited
		@_inited = true
		_self = @
		@_registry.init((err, result)->
			if result
				_self.subscribe(cb)
			else
				cb(err, false)
		)

	destroy: ->
		@_destroyed = true

	isDestroy: ->
		@_destroyed

	list: ->
		#TODO 压测决定：是否需要同时维护_invokers数组
		_invokers = []
		for url,invoker of @_invokerSet
			_invokers.push invoker
		_invokers

	subscribe: (initialCallback)->
		_self = @
		_self.initialCallbackIsCalled = false
		@_registry.subscribe(@_groupId, @_serviceId, (event)->
			Logger.info("serviceId:#{_self._serviceId} receive update event by #{_self._mergeType} mode:\
				#{JSON.stringify(event)}")
			try
				_self._merge(event)
				if not _self.initialCallbackIsCalled
					_self.initialCallbackIsCalled = true
					if initialCallback
						initialCallback(null, true)
			catch err
				Logger.error("subscribe _refreshInvoker error:"+err.stack)
				if not _self.initialCallbackIsCalled
					_self.initialCallbackIsCalled = true
					if initialCallback
						initialCallback(err, false)
		)

	unSubscribe: ->
		@_registry.unSubscribe(@_groupId, @_serviceId)

	removeInvoker: (invoker)->
		@_removeInvokerByUrl(invoker.getUrl())
		return

	_removeInvokerByUrl: (url)->
		_invoker = @_invokerSet[url]
		if _invoker
			_invoker.destroy()
			delete @_invokerSet[url]
		Logger.info("remove invoker #{url}")
		return

	_addInvokerIfAbsent: (url)->
		if not @_invokerSet[url]
			@_invokerSet[url] = new Invoker(@_configRef, url)
			Logger.info("add invoker #{url}")
		return

	_mergeComplete: (providerList)->
		# 全量对比，增量更新
		# no provider
		if not providerList or providerList.length < 1
			for url of @_invokerSet
				@_removeInvokerByUrl(url)

		_providerUrlSet = {}
		for url in providerList
			_providerUrlSet[url] = true

		#先删除被移除的provider
		for url of @_invokerSet
			if not _providerUrlSet[url]
				@_removeInvokerByUrl(url)
		#再创建新增的provider
		for url in providerList
			if not @_invokerSet[url]
				@_addInvokerIfAbsent(url)
		return

	_mergeIncrease: (providerMap)->
		return if not providerMap
		for url,cud of providerMap
			switch cud
				when Constants.FILE_CHANGE_EVENT.DELETE then @_removeInvokerByUrl(url)
				when Constants.FILE_CHANGE_EVENT.CREATE then @_addInvokerIfAbsent(url)
				when Constants.FILE_CHANGE_EVENT.UPDATE then @_removeInvokerByUrl(url); @_addInvokerIfAbsent(url)
		return

	_merge: (event)->
		if @_mergeType is MERGE_TYPE_INCREMENT
			@_mergeIncrease(event.providerChangeMap)
		else
			@_mergeComplete(event.providerWholeList)
		return

exports.RegistryDirectory = RegistryDirectory
