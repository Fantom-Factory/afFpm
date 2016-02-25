using util

internal class HelpCmd : FpmCmd {

	@Arg
	Str? cmd
	
	override Bool argsValid	:= true

	override Int go() {
		log.info("FPM Environment")
		log.info("---------------")
		log.info(fpmConfig.dump)

		cmd := Env.cur.args.getSafe(1)
		if (cmd != null) {
			cmdType := Type.find("afFpm::${cmd.capitalize}Cmd", false)
			if (cmdType != null && cmdType.doc?.trimToNull != null) {
				log.info("")
				log.info(cmd.toDisplayName)
				log.info("".padl(cmd.toDisplayName.size, '-'))
				log.info(cmdType.doc)
			}
		}

					// http://stackoverflow.com/a/24121322/1532548
		return 64	/* command line usage error */
	}

}
