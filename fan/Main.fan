
internal class Main {
	
	Int main(Str[] args) {
		fpmConfig := FpmConfig()
		
		cmdStr := args.first
		if (cmdStr == null)
			cmdStr = "dump"

		if (cmdStr == null || "\\? -? -h -help --help".split.contains(cmdStr))
			cmdStr = "help"

		cmdType := Main#.pod.type("${cmdStr.lower.capitalize}Cmd", false) ?: HelpCmd#
		
		// todo call HelpCmd explicitly
		
		args = args.rw
		if (args.size > 0)
			args.removeAt(0)

		ctorData := ArgParser() {
			it.resolveFns["repo"]	= |Str arg->Obj?| { parseRepository(arg, fpmConfig) }
			it.resolveFns["target"]	= |Str arg->Obj?| { parseTarget(arg) }
		}.parse(args, cmdType) {
			it[FpmCmd#log]			= StdLogger()
			it[FpmCmd#fpmConfig]	= fpmConfig
		}

		cmd := (FpmCmd) cmdType.make([Field.makeSetFunc(ctorData)])

		return cmd.run	
	}

	private static Depend? parseTarget(Str arg) {
		dep := arg.replace("@", " ")
		if (!dep.contains(" "))
			dep += " 0+"
		return Depend(dep, true)
	}

	private static Repository parseRepository(Str repo, FpmConfig fpmConfig) {
		// default, named, or localDir
		if (repo.isEmpty)
			return fpmConfig.repository("default")

		dir := toDir(repo)
		if (dir != null)
			return LocalDirRepository("dir", dir)

		return fpmConfig.repository(repo, true)
	}
	
	private static File? toDir(Str dirPath) {
		file := FileUtils.toFile(dirPath)
		// trailing slashes aren't added to dir paths that don't exist
		if (file.exists.not)
			file = file.uri.plusSlash.toFile
		if (file.isDir)
			return file
		return null
	}
}
