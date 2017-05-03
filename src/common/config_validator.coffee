RequiredFields = ["name", "groupId", "serviceId", "registry", "balance", "protocol"]
ThriftRequiredFields = ["serviceName"]
HttpRequiredFields = []
PROTOCOL_THRIFT = "thrift"
PROTOCOL_HTTP = "http"
ALLOW_PROTOCOL = [PROTOCOL_THRIFT, PROTOCOL_HTTP]

validate = (configObj)->
	return "config is null" if not configObj
	for field in RequiredFields
		if not configObj[field] or configObj[field] is ""
			return "config.#{field} is null"

	if configObj.protocol not in ALLOW_PROTOCOL
		return "config.protocol is not allow"

	if configObj.protocol is PROTOCOL_THRIFT
		if not configObj.thriftProperties
			return "config.thriftProperties is null"
		for field in ThriftRequiredFields
			if not configObj.thriftProperties[field]
				return "config.thriftProperties.#{field} is null"
		if (not configObj.thriftProperties.serviceJSPath or configObj.thriftProperties.serviceJSPath is '') and not\
		configObj.thriftProperties.serviceJSModule
			return "config.thriftProperties both serviceJSPath and serviceJSModule are null"
	else if configObj.protocol is PROTOCOL_HTTP
		# do nothing until HttpTransport is finished
		return

exports.validate = validate
