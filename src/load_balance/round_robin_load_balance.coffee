RoundRobinLoadBalance = {}

ClusterIdIndexMap = {}

RoundRobinLoadBalance.select = (clusterId, invokers, invocation)->
	if not invokers || invokers.length is 0
		return null
	if invokers.length is 1
		return invokers[0]
	RoundRobinLoadBalance._doSelect(clusterId, invokers, invocation)

RoundRobinLoadBalance._doSelect = (clusterId, invokers, invocation)->
	if not invokers or invokers.length < 1
		return null
	if not ClusterIdIndexMap[clusterId] and ClusterIdIndexMap[clusterId] isnt 0
		ClusterIdIndexMap[clusterId] = 0
		return invokers[0]
	else
		_index = ClusterIdIndexMap[clusterId]
		if _index+1 > invokers.length-1
			_index = 0
		else
			_index = _index+1
		ClusterIdIndexMap[clusterId] = _index
		return invokers[_index]

#权重的影响因素
RoundRobinLoadBalance.getWeight = (invoker, invocation)->
	return 0



exports.RoundRobinLoadBalance = RoundRobinLoadBalance