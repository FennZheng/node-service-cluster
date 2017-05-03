WeightRandomLoadBalance = {}

UrlWeight = {"127.0.0.1:9091":50}
DEFAULT_WEIGHT = 50

#根据权重来随机
WeightRandomLoadBalance.select = (clusterId, invokers, invocation)->
	if not invokers || invokers.length is 0
		return null
	if invokers.length is 1
		return invokers[0]
	WeightRandomLoadBalance._doSelect(clusterId, invokers, invocation)

WeightRandomLoadBalance._doSelect = (clusterId, invokers, invocation)->
	if not invokers or invokers.length < 1
		return null
	weightArray = []
	weightTotal = 0
	for invoker in invokers
		_weight = UrlWeight[invoker.originUrl]
		_weight = DEFAULT_WEIGHT if not _weight
		weightTotal += _weight
		weightArray.push _weight
	_selectWeight = parseInt(Math.random()*(weightTotal))
	_tmp = 0
	_index = 0
	for item in weightArray
		_tmp += item
		if _tmp > _selectWeight
			break
		else
			_index++
	return invokers[_index]

#权重的影响因素
WeightRandomLoadBalance.getWeight = (invoker, invocation)->
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


exports.WeightRandomLoadBalance = WeightRandomLoadBalance