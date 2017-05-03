node-service-cluster
=========================

License
-------
Licensed to the Apache Software Foundation (ASF) under one
or more contributor license agreements. See the NOTICE file
distributed with this work for additional information
regarding copyright ownership. The ASF licenses this file
to you under the Apache License, Version 2.0 (the
"License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing,
software distributed under the License is distributed on an
"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
KIND, either express or implied. See the License for the
specific language governing permissions and limitations
under the License.

## Install

    npm install node-service-cluster --registry=privite_repository_url

## Architecture

 
### Project Components:

Reference：对于一组provider的引用，可以理解为consumer访问provider的代理。

Cluster：一组invoker的抽象，cluster通过directory间接invoker。

Directory：包含了一组节点， 通过向注册中心注册服务变更事件，内部维护invoker的变更。

LoadBalance：提供负载能力，在Directory里通过策略选出一个提供服务的invoker，实现类：RoundRobinLoadBalance, RandomLoadBalance, RandomWithWeightBalance等。

Registry：是对注册中心的抽象实现。服务提供者向Registry注册，并暴露给Directory。服务消费者向Registry订阅，并最终通过Directory保存提供者和节点映射信息。实现类：ZookeeperRegistry, LocalRegistry。

Invoker：对provider的逻辑抽象，一个invoker对应一个provider。Invoker里封装了远程调用的具体细节。

*Client：管理与具体provide通讯协议调用，远程数据处理，编解码等细节。目前由第三方类库的连接池接管，如node-thrift-pool。

Transport：实现具体通讯协议和线程池等细节, 实现类：HttpTransport(暂未实现), ThriftTransport。

### Reference
一个reference实例为一个集群的引用，通过reference的invoke方法完成集群的调用。

<strong>1、初始化配置</strong>

    constructor: (config, serviceBundles)->
    
第一个参数为集群引用的配置，参考及说明：

    {
        "name": "funadx"m
    	"groupId": "main",
    	"serviceId": "funadx",
    	"registry": "http://127.0.0.1:2181",
    	#"registry": "./local_registry", 
    	"balance": "round_robin",
    	"protocol": "thrift",
    	"thriftProperties":{
    		"serviceName": "FunXPro",
    		#"serviceJSPath": "/Users/vernonzheng/Project/github/node-service-cluster/src/example/funadx_example/gen-nodejs/FunXPro.js",
    		"serviceJSModule": null,
    		"max_connections": 10,
    		"min_connections": 1,
    		"idle_timeout": 3000
    	},
    	"httpProperties":{
    		"max_connections": 10,
    		"min_connections": 1,
    		"idle_timeout": 3000
    	}
    }

* name: provider名称，尽量保持唯一
* groupId: provider所属组
* serviceId: provider服务标识
* registry: 如为url，则使用ZookeeperReigstry, 如为本地路径，则使用LoadRegistry
* balance: 负载均衡策略：目前有round_robin,random等
* protocol: 协议层实现：目前有thrift，http（缺）
* thriftProperties:
    * serviceName: 对应thrift的service概念
    * serviceJSPath: serviceJSModule为空时使用，对应thrift compile生成的模块绝对路径
    * serviceJSModule: 建议使用这个配置，通过require后的thrift模块赋值给该字段
    * max_connections: 每个provider的最大连接数
    * min_connections: 每个provider的最小连接数
    * idle_timeout: 连接空闲时间，超过则收回

第二个参数为serviceBundles（参考@microlens/hades-node-client模块）：

如果registry为ZookeeperRegitry，建议传入该值，如不传入，则在内部维护一个新serviceBundles。

<strong>2、调用</strong>

每次调用，需要实例化一个Invocation，调用reference.invoke(invocation)。

    constructor: (methodName, argument, attachments, callback)->
    
protocol为thrift时，argument和callback中reponse只支持为一个对象参数，多个返回参数请自行封装为一个对象
    
* methodName: 对应thrift compiler里的service名称，保持与config.thriftProperties.serviceName一致即可
* argument：调用参数
* attachments：可为空，内部用于调用统计，请求追溯等
* callback：回调函数，可为空，其中callback函数参数固定为（err, response)


### LocalRegistry and ZookeeperRegistry:

所有registry都支持动态变更，新增，删除，修改都会实时更新对应ClusterInvoker集合中的对应Invoker

<strong>1、LoadRegistry</strong>

服务注册到本地磁盘某一目录下，路径规则如下：

* {registryRoot}
    * /{groupId}
        * /{serviceId}
            * /{ip1:port2} #下划线和冒号两种都可以
            * /{ip1_port2}


<strong>2、ZookeeperRegistry</strong>

zookeeper节点规则：

* /hades
    * /services
        * /{groupId}
            * /{serviceId}
                * /{ip1:port1}
                * /{ip2:port2}


## Simple Thrift Example in provider/consumer model:

Also see detail: <a href="./example/simple-example">./example/simple-example</a>

Here is a Thrift server example as a provider:

```javascript
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




```


Here is a Thrift client example as a consumer:
```javascript
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
		"idle_timeout": 3000
	},
	"httpProperties":{
		"max_connections": 10,
		"min_connections": 1,
		"idle_timeout": 3000
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


```

## FunXPro examples
See detail: <a href="./example/funadx-example">./example/funadx-example</a>

