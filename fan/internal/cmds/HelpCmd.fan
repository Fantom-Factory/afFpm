using util

** Prints help on a given command.
@NoDoc	// Fandoc is only saved for public classes
class HelpCmd : FpmCmd {

	@Arg { help="The cmd to give help on" }
	Str? cmd
	
	override Bool argsValid	:= true

	override Int run() {
		super.printTitle
		if (Env.cur.args.size > 1)
			super.parseArgs(Env.cur.args[1..-1])
		return go
	}

	override Int go() {
		printTitle
		if (cmd == null) {
			log.info("FPM Environment:")
			log.info(fpmConfig.dump)

			logUsage
			return 64
		}

		cmdType := Type.find("afFpm::${cmd.capitalize}Cmd", false)
		if (cmdType == null) {
			log.info("Unknown command: ${cmd}")
			
			log.info("")
			logAvailableCmds

			log.info("")
			logUsage
			return 64
		}
		
		title := "Help: ${cmd.toDisplayName}"
		log.info(title)
		log.info("".padl(title.size, '-'))
		log.info(cmdType.doc?.trimEnd ?: "")
		
		((FpmCmd) cmdType.make).usage

					// http://stackoverflow.com/a/24121322/1532548
		return 64	/* command line usage error */
	}

	private Void logUsage() {
		log.info("Usage:")
		log.info("  fpm <command> [options]")
	}

	private Void logAvailableCmds() {
		log.info("Known commands:")
		logCmdSynopsis(SetupCmd#)
		logCmdSynopsis(HelpCmd#)
		log.info("")
		logCmdSynopsis(BuildCmd#)
		logCmdSynopsis(TestCmd#)
		logCmdSynopsis(RunCmd#)
		log.info("")
		logCmdSynopsis(InstallCmd#)
		logCmdSynopsis(UninstallCmd#)
		logCmdSynopsis(UpdateCmd#)
	}
	
	private Void logCmdSynopsis(Type cmdType) {
		doc := cmdType.doc?.trimEnd ?: ""
		idx := doc.index(".")
		nom := cmdType.name[0..<-3]
		doc = doc[0..<idx]
		log.info(nom.justr(9) + " - " + doc)
	}
}
