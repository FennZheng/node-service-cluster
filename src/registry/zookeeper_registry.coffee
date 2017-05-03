Hades = require("hades-node-client")
ServiceBundles = Hades.ServiceBundles
Logger = require("../common/logger").Logger
ERROR = require("../common/constants").ERROR

class ZookeeperRegistry
	constructor: (config, serviceBundles)->
		@type = "zookeeper"
		@_subscribeKeySet = {}
		if not config.registry or not config.serviceId
			throw new Error("config is null, registry[#{config.registry}] serviceId[#{config.serviceId}]")
		@_registry = config.registry
		@_groupId = config.groupId || "main"
		@_serviceId = config.serviceId
		@_serviceBundles = serviceBundles
		@_inited = false

		return

	init: (cb)->
		return cb(new Error(ERROR.REPEAT_INITED), false) if @_inited
		@_inited = true
		if not @_serviceBundles
			#若外部没注入，则内部新建维护一个serviceBundles
			ServiceBundles.on(ServiceBundles.EVENT_READY, ->
				Logger.info("ServiceBundles init successfully!!")
				cb(null, true)
			)
			ServiceBundles.on(ServiceBundles.EVENT_FAIL, (err)->
				Logger.error("ServiceBundles init error:#{err.stack}")
				cb(err, false)
			)
			ServiceBundles.init(_buildHadesConfig(@_registry, @_groupId, @_serviceId))
			ServiceBundles.on("error", (err)->
				Logger.error(err)
			)
			@_serviceBundles = ServiceBundles
		else
			cb(null, true)
		return

	_getRegistryKey: (groupId, serviceId)->
		groupId+"_"+serviceId

	subscribe: (groupId, serviceId, cb)->
		_subscribeKey = @_getRegistryKey(groupId, serviceId)
		return if @_subscribeKeySet[serviceId]
		if @_serviceBundles
			_eventId = _subscribeKey
			#ServiceBundles有个保护，如果节点被删除是不会触发，_eventId事件的
			@_serviceBundles.on(_eventId, (data)->
				_event = {}
				_event.providerWholeList = data
				cb(_event)
			)
			@_serviceBundles.watch(serviceId, _eventId)
		@_subscribeKeySet[serviceId] = cb

	unSubscribe: (groupId, serviceId)->
		_subscribeKey = @_getRegistryKey(groupId, serviceId)
		return if not @_subscribeKeySet[_subscribeKey]
		@_serviceBundles.removeListener(_subscribeKey, @_subscribeKeySet[_subscribeKey])
		delete @_subscribeKeySet[_subscribeKey]

	setServiceBundles: (serviceBundles)->
		@_serviceBundles = serviceBundles

setLogger = (logger)->
	Hades.initLog(logger) if logger

_buildHadesConfig = (registry, groupId, serviceId)->
	_tmp = {
		"configSource" : "remote",
		"zookeeperConf" : {
			"clusterList" : registry,
			"connectTimeout" : 2000,
			"retries" : 3,
			"sessionTimeout" : 10000
		},
		"localConf" : {
			"confRoot" : ""
		},
		"remoteConf" : {
			"groupId" : groupId,
			"projectId" : serviceId
		},
		"serviceDiscovery" : {
			"groupId" : "main"
		},
		"monitor" : {
			"disable" : true,
			"port" : 9882
		}
	}
	return _tmp

exports.setLogger = setLogger
exports.ZookeeperRegistry = ZookeeperRegistry