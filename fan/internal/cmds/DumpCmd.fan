
class DumpCmd : FpmCmd {
	
	new make(|This| f) : super(f) { }

	override Int run() {
		log.info("\nFPM Environment:")
		log.info(fpmConfig.dump)
		log.info("Usage:
		            fpm <command> [options]
		          
		          Example:
		            fpm help")

		return 0
	}
}
