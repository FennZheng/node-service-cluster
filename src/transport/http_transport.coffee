HttpAgent = require("fun_http_agent")
Http = require('http')

HttpTransport = {}

_defaultAgentOption = {
	keepAlive : true,
	maxSockets : 5
}

HttpTransport.createClientPool = (config, urlObj)->
	agent = new HttpAgent(_defaultAgentOption)
	return agent

HttpTransport.encode = (invocation)->
	#TODO 这里只是取巧处理，应该由transport编解码后发送
	#TODO 因为Server端不用node-service-cluster，所以不用自己实现网络协议
	_cb = invocation.getCallBack()
	invocation.removeCallBack()

	return {
		"data": JSON.stringify(invocation),
		"callback": _cb
	}

#TODO 临时处理
HttpTransport.send = (pool, urlObj, invocation)->
	_tmp = HttpTransport.encode(invocation)
	_cb = _tmp.callback
	_data = _tmp.data
	options = {}
	options.host = url.host
	options.port = url.port
	options.agent = pool
	options.method = "POST"
	timeout = 200
	if not options.headers
		options.headers = {}
	if not options.headers['Content-Type']
		options.headers['Content-Type'] = 'application/x-www-form-urlencoded'

	if not options.headers['Content-Length']
		options.headers['Content-Length'] = Buffer.byteLength(_data, 'utf8')

	req = Http.request(options, (res)->
		res.setEncoding('utf8')
		resData = ''
		res.on('data', (chunk)->
			resData += chunk
		);
		res.on("end", ()->
			resTime = Date.now() - _startTime
			_cb(res.statusCode, resTime, null, resData) if _cb
		)
	)
	_startTime = Date.now()

	_socketRef = null
	req.on("socket",(socket)->
		_socketRef = socket
	)
	req.setTimeout timeout,()->
		req.abort()

	req.on 'error', (err)->
		resTime = Date.now() - _startTime
		_cb(null, resTime, err, null) if _cb

	req.write(_data)
	req.end()

exports.HttpTransport = HttpTransport
