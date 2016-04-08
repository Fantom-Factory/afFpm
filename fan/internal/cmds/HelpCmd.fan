using util

** Prints help on a given command.
@NoDoc	// Fandoc is only saved for public classes
class HelpCmd : FpmCmd {

	@Arg { help="The cmd to give help on" }
	Str? cmd
	
	override Bool argsValid	:= true

	new make() : super.make() { }

	override Int run() {
		super.printTitle
		return go
	}

	override Int go() {
		if (cmd == null) {
			log.info("FPM Environment:")
			log.info(fpmConfig.dump)

			logUsage
			
			log.info("")
			log.info("Example:")
			log.info("  fpm help")
			return 64
		}

		if (cmd == "help" && Env.cur.args.size == 0) {
			logAvailableCmds

			log.info("")
			logUsage
			return 0
		}
		
		if (Env.cur.args.size > 1)
			super.parseArgs(Env.cur.args[1..-1])
		
		cmdType := Type.find("afFpm::${cmd.capitalize}Cmd", false)
		if (cmdType == null) {
			log.info("Unknown command: ${cmd}")
			
			log.info("")
			logAvailableCmds

			log.info("")
			logUsage
						// http://stackoverflow.com/a/24121322/1532548
			return 64	/* command line usage error */
		}
		
		title := "Help: ${cmd.toDisplayName}"
		log.info(title)
		log.info("".padl(title.size, '-'))
		log.info(cmdType.doc?.trimEnd ?: "")
		
		buf := StrBuf()
		((FpmCmd) cmdType.make).usage(buf.out)
		use := buf.toStr.splitLines.exclude { it.contains("-help, -?") }.join("\n").trimEnd
		log.info(use)
		return 0
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
		nom := cmdType.name[0..<-3].decapitalize
		doc = doc[0..<idx]
		log.info(nom.justr(9) + " - " + doc)
	}
}
