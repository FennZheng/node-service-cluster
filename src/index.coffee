Reference = require("./cluster/reference").Reference
Invocation = require("./cluster/invocation").Invocation
LoadBalance = require("./load_balance")
Logger = require("./common/logger").Logger

exports.LOAD_BALANCE_RANDOM = LoadBalance.LOAD_BALANCE_RANDOM
exports.LOAD_BALANCE_ROUND_ROBIN = LoadBalance.LOAD_BALANCE_ROUND_ROBIN
exports.LOAD_BALANCE_WEIGHT_RANDOM = LoadBalance.LOAD_BALANCE_WEIGHT_RANDOM
exports.LOAD_BALANCE_DEFAULT = LoadBalance.LOAD_BALANCE_DEFAULT

exports.Reference = Reference
exports.Invocation = Invocation

exports.Logger = Logger
exports.setLogger = (logger)->
	Logger.init(logger)