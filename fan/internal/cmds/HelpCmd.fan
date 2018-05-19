
** Prints help on a given command.
@NoDoc	// Fandoc is only saved for public classes
class HelpCmd : FpmCmd {
	
	@Arg { help="The cmd to give help on" }
	Str? cmd

	new make(|This| f) : super(f) { }

	override Int run() {
		if (cmd == null) {
			logAvailableCmds
			return 0
		}

		cmdType := FpmEnv#.pod.type("${cmd.capitalize}Cmd", false)
		if (cmdType == null) {
			log.info("Unknown command: ${cmd}\n")
			logAvailableCmds
			return invalidArgs
		}

		logHelp(cmdType)
		usage(cmd, cmdType)
		return 0
	}

	Void logHelp(Type cmdType) {
		cmd := cmdType.name[0..<-3]
		title := "FPM ${cmd.toDisplayName}"
		log.info(title)
		log.info("".padl(title.size, '-'))
		log.info(cmdType.doc?.trimEnd ?: "")		
	}

	private Void logAvailableCmds() {
		title := "Fantom Pod Manager (FPM) v${typeof.pod.version}"
		log.info(title)
		log.info("".padl(title.size, '-'))
		log.info("")
		log.info("Known commands:")
		// FIXME setup cmd
//		logCmdSynopsis(SetupCmd#)
		logCmdSynopsis(HelpCmd#)
		log.info("")
		logCmdSynopsis(BuildCmd#)
		logCmdSynopsis(TestCmd#)
		logCmdSynopsis(RunCmd#)
		log.info("")
		logCmdSynopsis(QueryCmd#)
		logCmdSynopsis(InstallCmd#)
		logCmdSynopsis(DeleteCmd#)
//		logCmdSynopsis(UpdateCmd#)
		log.info("\nUsage:
		            fpm <command> [options]
		          
		          Example:
		            fpm help install")
	}
	
	private Void logCmdSynopsis(Type cmdType) {
		doc := cmdType.doc?.trimEnd ?: ""
		idx := doc.index(".")
		nom := cmdType.name[0..<-3].decapitalize
		doc = doc[0..<idx]
		log.info(nom.justr(9) + " - " + doc)
	}
	
	// ------------
	
	** Print usage of arguments and options.
	private Int usage(Str cmd, Type cmdType) {
		// get list of argument fields
		args := cmdType.fields.findAll |f| { f.hasFacet(Arg#) }.exclude { it.hasFacet(NoDoc#) }

		// get list of all documented options
		opts := cmdType.fields.findAll |f| { f.hasFacet(Opt#) }.exclude { it.hasFacet(NoDoc#) }

		// format args/opts into columns
		argRows := usagePad(args.map |f| { usageArg(f) })
		optRows := usagePad(opts.map |f| { usageOpt(f) })

		// format summary line
		argSummary := args.join(" ") |field| {
			s := "<" + field.name + ">"
			if (field.type.fits(List#)) s += "*"
			return s
		}

		log.info("\nUsage:")
		log.info("  fpm $cmd [options] $argSummary")
		usagePrint("\nArguments:", argRows)
		usagePrint("\nOptions:", optRows)
		return 1
	}

	private Str[] usageArg(Field field) {
		name := field.name
		help := field.facet(Arg#)->help as Str
		return [name, help]
	}

	private Str[] usageOpt(Field field) {
		name := field.name
		help := field.facet(Opt#)->help as Str
		Str[] aliases := field.facet(Opt#)->aliases

		col1 := "-$name"
		if (!aliases.isEmpty)			col1 += ", -" + aliases.join(", -")
		//if (!field.type.fits(Bool#))	col1 += " <$field.type.name>"

		col2 := help
		return [col1, help]
	}
	
	private Str[][] usagePad(Str[][] rows) {
		if (rows.isEmpty) return rows
		Int max := rows.map |row| { row[0].size }.max
		pad := 20.min(2 + max)
		rows.each |row| { row[0] = row[0].padr(pad) }
		return rows
	}

	private Void usagePrint(Str title, Str[][] rows) {
		if (rows.isEmpty) return
		log.info(title)
		rows.each |row| { log.info("  ${row[0]}  ${row[1]}") }
	}
}
