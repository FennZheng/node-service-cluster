#9007199254740992 16位,取15位
MAX_NUMBER = 900719925474099
#refreh each minute
SNAPSHOT_REFRESH_INTERVAL = 60000
#connect refused一定次数后认为server unreachable，从Registry移除此Invoker
DEFAULT_SERVER_UNREACHABLE_THRESHOLD = 50

#TODO 增加错误统计，然后失败
class InvokerStatistic

	constructor: (config)->
		@_innerStats = {}
		@_setSnapshotAutoRefresh()
		@_connectRefusedConstantsCount = 0
		@isServerUnreachable = false
		@_serverUnreachableThreshold = config.serverUnreachableThreshold || DEFAULT_SERVER_UNREACHABLE_THRESHOLD

	_setSnapshotAutoRefresh: ->
		self = @
		refreshAll = ->
			for method,stat of self._innerStats
				stat.lastMinute.successCount = stat.current.successCount - stat.snapshot.successCount
				stat.lastMinute.failCount = stat.current.failCount - stat.snapshot.failCount
				stat.lastMinute.costTotal = stat.current.costTotal - stat.snapshot.costTotal

				stat.snapshot.successCount = stat.current.successCount
				stat.snapshot.failCount = stat.current.failCount
				stat.snapshot.costTotal = stat.current.costTotal
				if stat.current.successCount > MAX_NUMBER or stat.current.failCount > MAX_NUMBER or \
				stat.current.costTotal > MAX_NUMBER
					stat.current.successCount = 0
					stat.current.failCount = 0
					stat.current.costTotal = 0
					stat.snapshot.successCount = 0
					stat.snapshot.failCount = 0
					stat.snapshot.costTotal = 0

				stat.snapshotRefreshTime = Date.now()
		setInterval(refreshAll, SNAPSHOT_REFRESH_INTERVAL)

	#commit a finished invoke to stats
	complete: (err, invocation)->
		_endTime = Date.now()
		_statRef = @_getStat(invocation.getMethodName())
		if err
			_statRef.current.failCount++
			if err.message is "connect ECONNREFUSED"
				@_connectRefusedConstantsCount += 1
			if @_connectRefusedConstantsCount > @_serverUnreachableThreshold
				@isServerUnreachable = true
		else
			_statRef.current.successCount++
			@_connectRefusedConstantsCount = 0
		_statRef.current.costTotal += (_endTime - invocation.getAttachment("startTime"))
		_statRef.refreshTime = _endTime
		return

	_getStat: (methodName)->
		if not @_innerStats[methodName]
			@_innerStats[methodName] = @_newStat(methodName)
		return @_innerStats[methodName]

	_newStat: (methodName)->
		_stat = {
			"snapshot": {
				"successCount": 0
				"failCount": 0
				"costTotal": 0
			}
			"current": {
				"successCount": 0
				"failCount": 0
				"costTotal": 0
			},
			"lastMinute": {
				"successCount": 0
				"failCount": 0
				"costTotal": 0
			}
			"refreshTime": 0
			"refreshInterval": SNAPSHOT_REFRESH_INTERVAL
		}
		@_innerStats[methodName] = _stat
		return _stat

	export: ->
		outputStatistic = {}
		for methodName,stat of @_innerStats
			outputStatistic[methodName] = {
				"current": {
					"successCount": stat.current.successCount
					"failCount": stat.current.failCount
					"successPercent": ((stat.current.successCount+1)*100/(stat.current.failCount+stat.current.successCount+1)).toFixed(2)
					"totalCount": stat.current.successCount+stat.current.failCount
					"costPerInvoke": (stat.current.costTotal/(stat.current.successCount+stat.current.failCount+1)).toFixed(2)
				}
				"lastMinute": {
					"successCount": stat.lastMinute.successCount
					"failCount": stat.lastMinute.failCount
					"successPercent": ((stat.lastMinute.successCount+1)*100/(stat.lastMinute.failCount+stat.lastMinute.successCount+1)).toFixed(2)
					"totalCount": stat.lastMinute.successCount+stat.lastMinute.failCount
					"costPerInvoke": (stat.lastMinute.costTotal/(stat.lastMinute.successCount+stat.lastMinute.failCount+1)).toFixed(2)
				}
				"refreshTime": stat.refreshTime
				"refreshInterval": stat.refreshInterval
			}
		#深拷贝
		JSON.parse(JSON.stringify(outputStatistic))

exports.InvokerStatistic = InvokerStatistic