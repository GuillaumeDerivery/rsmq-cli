cli = require( "./_global_opt" )( true )

cli
	.usage('count [options]')
	.parse(process.argv)

rsmq = require( "./_rsmq" )( cli )
processUtil = require( "./_process" )( rsmq )

rsmq.stats( true, processUtil.final )