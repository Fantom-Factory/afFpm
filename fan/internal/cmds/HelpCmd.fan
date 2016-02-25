
internal class HelpCmd : FpmCmd {

	override Bool argsValid	:= true

	override Int go() {
		
		log.info("FPM Environment")
		log.info("---------------")
		log.info(fpmConfig.dump)
		
					// http://stackoverflow.com/a/24121322/1532548
		return 64	/* command line usage error */
	}

}
