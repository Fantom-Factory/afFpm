
internal class Main {
	
	Int main(Str[] args) {
		
		cmdStr := args.first
		if (cmdStr == null || "\\? -? -h -help --help".split.contains(cmdStr))
			cmdStr = "help"

		cmdType := Main#.pod.type("${cmdStr.lower.capitalize}Cmd", false) ?: HelpCmd#
		
		// todo call HelpCmd explicitly
		
		args = args.rw
		if (args.size > 0)
			args.removeAt(0)

		cmd := (FpmCmd) ArgParser().parse(args, cmdType)

		return cmd.run		
	}
}

