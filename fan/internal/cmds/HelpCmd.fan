using util

** Prints help on a given command.
@NoDoc	// Fandoc is only saved for public classes
class HelpCmd : FpmCmd {

	@Arg
	Str? cmd
	
	override Bool argsValid	:= true

	override Int go() {
		
		cmd := Env.cur.args.getSafe(1)
		if (cmd != null) {
			cmdType := Type.find("afFpm::${cmd.capitalize}Cmd", false)
			if (cmdType != null && cmdType.doc?.trimToNull != null) {
				title := "Help: ${cmd.toDisplayName}"
				log.info(title)
				log.info("".padl(title.size, '-'))
				log.info(cmdType.doc)
			}
			((FpmCmd) cmdType.make).usage
		} else {
			log.info("FPM Environment")
			log.info("---------------")
			log.info(fpmConfig.dump)
			
			// FIXME print cmd synopsis 
		}

					// http://stackoverflow.com/a/24121322/1532548
		return 64	/* command line usage error */
	}

}
