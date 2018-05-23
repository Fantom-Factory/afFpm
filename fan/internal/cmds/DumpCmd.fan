
internal class DumpCmd : FpmCmd {
	
	new make(|This| f) : super(f) { }

	override Int run() {
		log.info("FPM (${FpmEnv#.pod.version}) Environment:")
		log.info(fpmConfig.dump)
		log.info("Usage:
		            fpm <command> [options]
		          
		          Example:
		            fpm help")

		return 0
	}
}
