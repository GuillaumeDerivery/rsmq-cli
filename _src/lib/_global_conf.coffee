fs = require("fs")
ini = require('ini')
_ = require('lodash')

_names = [ "port", "host", "ns", "timeout", "qname" ]

_defaults = 
	port: 6379
	host: "127.0.0.1"
	ns: "rsmq"
	timeout: 3000

class Config extends require( "mpbasic" )()
	constructor:->
		super

		@cnf = @initConfigFile()
		return

	initConfigFile: =>
		try
			_content = @readConfigContent()
		catch err
			if err.message.indexOf( "ENOENT" ) is 0
				# create config file
				_content = @defaultConfig
				@writeConfigFile( _content )
			else
				throw err

		_asNumber = []
		for _k, _v of _defaults when _.isNumber( _v )
			_asNumber.push( _k ) 
		_decoded = ini.decode( _content )
		for _scope, _cnf of _decoded
			for _k in _asNumber when _cnf[ _k ]?
				_i = parseInt( _cnf[ _k ], 10 )
				if not isNaN( _i )
					_decoded[ _scope ][ _k ] = _i 
		return _decoded

	defaultConfig: """
[default]
port=#{_defaults.port}
host=#{_defaults.host}
ns=#{_defaults.ns}
timeout=#{_defaults.timeout}
				"""

	writeConfigFile: ( _content, cb )=>
		if cb?
			fs.writeFile( @getPath(), _content, cb )
			return
		else
			return fs.writeFileSync( @getPath(), _content )
		return

	readConfigContent: ( cb )=>
		if cb?
			fs.readFile( @getPath(), cb )
			return
		else
			return fs.readFileSync( @getPath() ).toString()

	save: ( cb )=>
		return @writeConfigFile( ini.encode( @cnf ), cb )

	getPath: =>
		_home = process.env[ "HOME" ] or process.env[ "HOMEPATH" ] or process.env[ "USERPROFILE" ]
		return "#{_home}/.rsmq" 

	read: ( scope = "default" )=>
		if scope is "default"
			return @cnf[ scope ]

		return _.extend( {}, @read(), @cnf[ scope ] )

	getConfig: ( _n, scope = "default", cb )=>
		if _n not in _names
			@_handleError( cb, "EINVALIDNAME" )
			return

		_cnf = @read( scope )

		cb( null, _cnf[ _n ] )
		return


	setConfig: ( _n, _v, scope = "default", cb )=>
		if _n not in _names
			@_handleError( cb, "EINVALIDNAME" )
			return
		if not @cnf[ scope ]?
			@cnf[ scope ] = {}

		if _v?
			_def = _defaults[ _n ]
			if _.isNumber( _def )
				_iv = parseInt( _v, 10 )
				if isNaN( _iv )
					@_handleError( cb, "ENOTNUMBER" )
					return 
				@cnf[ scope ][ _n ] = _iv
			else
				@cnf[ scope ][ _n ] = _v
		else if scope is "default" and _defaults[ _n ]?
			@cnf[ scope ][ _n ] = _defaults[ _n ]
		else
			delete @cnf[ scope ][ _n ]

		@save ( err )=>
			if err
				cb( err )
				return
			cb( null, @read(scope) )
			return
		return


	ERRORS: =>
		return @extend super,
			"EINVALIDNAME": [ 400, "Invalid config type. Only `#{_names.join( "`, `" )}` are allowed. " ]
			"ENOTNUMBER": [ 400, "This configuration has to be a number" ]

module.exports = new Config()