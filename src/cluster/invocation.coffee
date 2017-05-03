class Invocation
	#attachments为每次请求的附带信息，需要区分出类库信息和用户信息
	constructor: (methodName, argument, attachments, callback)->
		if not methodName or methodName is ""
			throw new Error("new Invocation error: methodName is null")
		@_methodName = methodName
		@_argument = argument
		if attachments
			@_attachments = attachments
		else
			@_attachments = {}
		@_callback = callback

	getMethodName: ->
		@_methodName

	getArgument: ->
		@_argument

	setAttachment: (key, value)->
		@_attachments[key] = value if key

	getAttachment: (key)->
		@_attachments[key]

	getAttachments: ->
		@_attachments

	getCallBack: ->
		@_callback

	setCallBack: (cb)->
		@_callback = cb

	removeCallBack: ->
		@_callback = null

Invocation.validate = (invocation)->
	if not invocation
		return "invocation is null"
	if not invocation.getMethodName() or invocation.getMethodName() is ""
		return "invocation.methodName is null"
	return null

exports.Invocation = Invocation