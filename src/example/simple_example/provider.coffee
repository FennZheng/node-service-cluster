Thrift = require('thrift')
UserStorage = require('./gen-nodejs/UserStorage.js')
Ttypes = require('./gen-nodejs/user_types');

newServer = (port)->
	users = {}
	server = Thrift.createServer(UserStorage, {
		store: (user, result)->
			console.log("server[#{port}] stored:", user.uid)
			users[user.uid] = user
			result(null);
		,
		retrieve: (uid, result)->
			console.log("server[#{port}] retrieved:", uid)
			result(null, users[uid])

	})
	server.listen(port);


Hades = require("hades-node-client")
Hades.initLog(null)
ServiceBundles = Hades.ServiceBundles
ConfigObj = {
	"configSource" : "remote",
	"zookeeperConf" : {
		"clusterList" : "localhost:2181",
		"connectTimeout" : 2000,
		"retries" : 3,
		"sessionTimeout" : 10000
	},

	"localConf" : {
		"confRoot" : "/Users/vernonzheng/Project/github/hades-node-client/src/setting/"
	},

	"remoteConf" : {
		"groupId" : "main",
		"projectId" : "ad"
	},

	"serviceDiscovery" : {
		"groupId" : "main",
		"localCacheDir" : "/Users/vernonzheng/Project/github/hades-node-client/src/setting/",
		"mode": "normal"
	},
	"monitor" : {
		"disable" : false,
		"port" : 9881
	}
}

TEST_SERVICE_REGISTRY = "ad"
TEST_SERVICE_GET = "ad"

ServiceBundles.on(ServiceBundles.EVENT_READY, ()->
	ServiceBundles.watch(TEST_SERVICE_GET, (err, data)->
		console.log(JSON.stringify(data))
	)
	newServer(9090)
	newServer(9091)
	ServiceBundles.register(TEST_SERVICE_REGISTRY, "127.0.0.1:9090", "Meta-ddd", (err, result)->
		console.log("register result:#{result}, err:#{err}")
		ServiceBundles.register(TEST_SERVICE_REGISTRY, "127.0.0.1:9091", "Meta-ddd", (err, result)->
			console.log("register result:#{result}, err:#{err}")
		)
	)
)


ServiceBundles.on(ServiceBundles.EVENT_FAIL, (err)->
	console.error("ServiceBundles init error:#{err.stack}")
)
ServiceBundles.init(ConfigObj)



