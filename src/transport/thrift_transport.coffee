Thrift = require("thrift")
ThriftPool = require("node-thrift-pool")
Logger = require("../common/logger").Logger

#再优化吧
ThriftTransport = {}

ThriftTransport.createClientPool = (config, urlObj)->
	if not config.thriftProperties
		throw new Error("node-service-cluster clientPool init fail: config.thriftProperties is null")
	_options = {
		host: urlObj.host
		port: urlObj.port
		log: false
		max_connections: config.thriftProperties.max_connections || 10
		min_connections: config.thriftProperties.min_connections || 1
		idle_timeout: config.thriftProperties.idle_timeout || 30000
	}
	if config.thriftProperties.serviceJSModule
		Service = config.thriftProperties.serviceJSModule
	else if config.thriftProperties.serviceJSPath and config.thriftProperties.serviceJSPath isnt ""
		Service = require(config.thriftProperties.serviceJSPath)

	_thrift_options = {
	}

	clientPool = ThriftPool(Thrift, Service, _options, _thrift_options);
	return clientPool

ThriftTransport.send = (pool, urlObj, invocation)->
	#Logger.debug("thriftTransport send data to"+JSON.stringify(urlObj))
	_methodName = invocation.getMethodName()
	_cb = invocation.getCallBack()
	pool[_methodName](invocation.getArgument(), (err, resData)->
		_cb(err, resData)
	)
	return

exports.ThriftTransport = ThriftTransport