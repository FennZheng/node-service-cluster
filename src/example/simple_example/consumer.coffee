Thrift = require('thrift')
Logger = require("../../index").Logger
UserStorage = require('./gen-nodejs/UserStorage.js')
Ttypes = require('./gen-nodejs/user_types')
Hades = require("hades-node-client")
ServiceBundles = Hades.ServiceBundles

Logger.isDebugEnable = true

user = new Ttypes.UserProfile({
	uid: 1,
	name: "Mark Slee",
	blurb: "I'll find something to put here."
})

Reference = require("../../index").Reference
Invocation = require("../../index").Invocation

#一个reference只对应一个service
funadxConfig = {
	"name": "funadx"
	"groupId": "main"
	"serviceId": "ad",
	"registry": "127.0.0.1:2181",
	"balance": "round_robin",
	"protocol": "thrift",
	"thriftProperties":{
		"serviceName": "UserStorage",
		"serviceJS": null,
		"max_connections": 10,
		"min_connections": 1,
		"idle_timeout": 3000,
		"timeout": 50
	},
	"httpProperties":{
		"max_connections": 10,
		"min_connections": 1,
		"idle_timeout": 3000,
		"timeout": 50
	}
}

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


ServiceBundles.on(ServiceBundles.EVENT_FAIL, (err)->
	console.error("ServiceBundles init error:#{err.stack}")
)
ServiceBundles.init(_buildHadesConfig("127.0.0.1:2181", "main", "ad"))
ServiceBundles.on("error", (err)->
	console.error(err)
)

funadxReference = null

ServiceBundles.on(ServiceBundles.EVENT_READY, ->
	#console.log("ServiceBundles init successfully!!")
	funadxConfig.thriftProperties
	funadxReference = new Reference(funadxConfig, ServiceBundles)
	funadxReference.init((err, result)->
		setInterval(->
			invocation1 = new Invocation("store", user, null, (err, resData)->
				console.log("get store res:", err, resData)
			)
			funadxReference.invoke(invocation1)
			funadxReference.invoke(invocation1)
			invocation2 = new Invocation("retrieve", user.uid, null, (err, resData)->
				console.log("get retrieve res:", err, resData)
			)
			funadxReference.invoke(invocation2)
			#funadxReference.invoke(invocation2)
		,10000)
	)
	#TODO 这里还没测试
	process.on("exit", ->
		console.log(JSON.stringify(funadxReference.getStatistic(), null, "\t")) if funadxReference
	)
	process.on("SIGINT", ->
		console.log(JSON.stringify(funadxReference.getStatistic(), null, "\t")) if funadxReference

	)

)

#
