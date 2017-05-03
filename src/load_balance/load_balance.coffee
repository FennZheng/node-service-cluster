###
后续如果要加算法，参考如下：
FCFS (First Come First Served)
SPF (Shortest Process First)
HRRF (Highest Response Ratio First)
RR (Round Robin)
Multi-Level Feedback Queue
FPF (First Priority First)
###
RandomLoadBalance = require("./random_load_balance").RandomLoadBalance
WeightRandomLoadBalance = require("./weight_random_load_balance").WeightRandomLoadBalance
RoundRobinLoadBalance = require("./round_robin_load_balance").RoundRobinLoadBalance

LOAD_BALANCE_RANDOM = "random"
LOAD_BALANCE_ROUND_ROBIN = "round_robin"
LOAD_BALANCE_WEIGHT_RANDOM = "weight_random"

BalanceMap = {
	LOAD_BALANCE_RANDOM: RandomLoadBalance
	LOAD_BALANCE_ROUND_ROBIN: RoundRobinLoadBalance
	LOAD_BALANCE_WEIGHT_RANDOM: WeightRandomLoadBalance
}

getLoadBalance = (loadBalance)->
	return RoundRobinLoadBalance if not loadBalance
	_tmp = BalanceMap[loadBalance]
	_tmp = RoundRobinLoadBalance if not _tmp
	_tmp

exports.LOAD_BALANCE_RANDOM = LOAD_BALANCE_RANDOM
exports.LOAD_BALANCE_ROUND_ROBIN = LOAD_BALANCE_ROUND_ROBIN
exports.LOAD_BALANCE_WEIGHT_RANDOM = LOAD_BALANCE_WEIGHT_RANDOM
exports.LOAD_BALANCE_DEFAULT = LOAD_BALANCE_ROUND_ROBIN
exports.getLoadBalance = getLoadBalance

