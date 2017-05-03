RandomLoadBalance = {}

#根据权重来随机
RandomLoadBalance.select = (clusterId, invokers, invocation)->
	if not invokers || invokers.length is 0
		return null
	if invokers.length is 1
		return invokers[0]
	RandomLoadBalance._doSelect(clusterId, invokers, invocation)

RandomLoadBalance._doSelect = (clusterId, invokers, invocation)->
	if not invokers or invokers.length < 1
		return null
	# 如果权重相同或权重为0则均等随机
	# invokers
	for invoker in invokers
		invoker.getWeight()
	_index = parseInt(Math.random()*(invokers.length))
	return invokers[_index]

#权重的影响因素
RandomLoadBalance.getWeight = (invoker, invocation)->
	return 0

###
	getWeight: (invoker, invocation)->
		weight = invoker.getUrl().getMethodParameter(invocation.getMethodName(), Constants.WEIGHT_KEY, Constants.DEFAULT_WEIGHT)
		if weight > 0
			timestamp = invoker.getUrl().getParameter(Constants.TIMESTAMP_KEY, 0)
			if timestamp > 0
				uptime = Date.now() - timestamp
				warmup = invoker.getUrl().getParameter(Constants.WARMUP_KEY, Constants.DEFAULT_WARMUP)
				if uptime > 0 and uptime < warmup
					weigth = calculateWarmupWeight(uptime, warmup, weight)
		return weight

###


exports.RandomLoadBalance = RandomLoadBalance