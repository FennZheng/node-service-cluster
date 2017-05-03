Hades = require("hades-node-client")
ServiceBundles = Hades.ServiceBundles
Logger = require("../common/logger").Logger
ERROR = require("../common/constants").ERROR
Path = require("path")
Chokidar = require("chokidar")
Constants = require("../common/constants").Constants

# local file format：ip:port
PROVIDER_URL_REGEX = new RegExp("(([a-zA-Z0-9\._-]+\.[a-zA-Z]{2,6})|\
([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}))(_[0-9]{1,4})*")

class LocalRegistry
	constructor: (config)->
		@type = "local"
		@_subscribeKeySet = {}
		if not config.registry or not config.serviceId
			throw new Error("config is null, registry[#{config.registry}] serviceId[#{config.serviceId}]")
		@_registry = config.registry
		@_groupId = config.groupId || "main"
		@_serviceId = config.serviceId
		@_serviceBundles = null
		@_inited = false

		return

	init: (cb)->
		return cb(new Error(ERROR.REPEAT_INITED), false) if @_inited
		@_inited = true

		cb(null, true)

	_getRegistryKey: (groupId, serviceId)->
		groupId+"_"+serviceId

	_buildPath: (registry, groupId, serviceId)->
		Path.normalize(Path.join(registry, groupId, serviceId))

	_buildEvent: (path, cud)->
		_event = {}
		_event.providerChangeMap = {}
		_event.providerChangeMap[path] = cud
		_event

	_resolveUrl: (path)->
		_tmp = path.substring(path.lastIndexOf('/')+1, path.length)
		if _tmp
			return _tmp.replace("_", ":")
		else
			return ""

	subscribe: (groupId, serviceId, cb)->
		_subscribeKey = @_getRegistryKey(groupId, serviceId)
		return if @_subscribeKeySet[_subscribeKey]
		watcher = Chokidar.watch(@_buildPath(@_registry, groupId, serviceId), {
			persistent: true,
			recursive: false,
			encoding: 'utf-8',
			ignored: /[\/\\]\./
		})
		watcher.on("add", (path, stats) =>
			url = @_resolveUrl(path)
			if PROVIDER_URL_REGEX.test(url)
				cb(@_buildEvent(url, Constants.FILE_CHANGE_EVENT.CREATE))
			return
		)
		#delete file emit event:unlink and add in order
		###
		watcher.on("change", (path, stats) =>
			url = @_resolveUrl(path)
			if PROVIDER_URL_REGEX.test(url)
				cb(_self._buildEvent(url, Constants.FILE_CHANGE_EVENT.UPDATE))
			return
		)
		###
		watcher.on("unlink", (path)=>
			url = @_resolveUrl(path)
			if PROVIDER_URL_REGEX.test(url)
				cb(@_buildEvent(url, Constants.FILE_CHANGE_EVENT.DELETE))
			return
		)
		@_subscribeKeySet[_subscribeKey] = watcher
		return

	unSubscribe: (groupId, serviceId)->
		_subscribeKey = _getRegistryKey(groupId, serviceId)
		return if not @_subscribeKeySet[_subscribeKey]
		watcher = @_subscribeKeySet[_subscribeKey]
		watcher.close()
		delete @_subscribeKeySet[_subscribeKey]

	setServiceBundles: (serviceBundles)->
		@_serviceBundles = serviceBundles

exports.LocalRegistry = LocalRegistry