
internal class Main {
	
	Int main(Str[] args) {
		args		= args.rw
		fpmConfig	:= FpmConfig()

		cmdStr		:= args.first
		if (cmdStr == null)
			cmdStr = "dump"

		if ("\\? -? -h -help --help".split.contains(cmdStr))
			cmdStr = "help"
		
		// FIXME update cmd
		if (cmdStr == "update")
			cmdStr = "install"

		cmdType := Main#.pod.type("${cmdStr.lower.capitalize}Cmd", false)
		if (cmdType == null)
			cmdType = HelpCmd#
		else if (args.size > 0)
			args.removeAt(0)
		
		ctorData := ArgParser() {
			it.resolveFns["repo"]	= |Field field, Str arg->Obj?| { parseRepo(field, arg, fpmConfig) }
			it.resolveFns["target"]	= |Field field, Str arg->Obj?| { parseTarget(field, arg) }
		}.parse(args, cmdType) {
			it[FpmCmd#log]			= StdLogger()
			it[FpmCmd#fpmConfig]	= fpmConfig
		}

		cmd := (FpmCmd) cmdType.make([Field.makeSetFunc(ctorData)])

		if (cmd.debug)
			cmd.log.level = LogLevel.debug
		
		return cmd.run	
	}

	private static Depend? parseTarget(Field field, Str arg) {
		dep := arg.replace("@", " ")
		if (!dep.contains(" "))
			dep += " 0+"
		return Depend(dep, true)
	}

	private static Repository? parseRepo(Field field, Str repo, FpmConfig fpmConfig) {
		// default, named, or localDir
		if (repo.isEmpty)
			return field.type.isNullable ? null : fpmConfig.repository("default")

		fpmRepo := fpmConfig.repository(repo)
		if (fpmRepo != null)
			return fpmRepo
		
		repoUrl := Uri(repo, false)
		if (repoUrl?.scheme == "http" || repoUrl?.scheme == "https")
			return RemoteFanrRepository("unnamed", repoUrl)
		
		dir := toDir(repo)
		if (dir != null)
			return LocalDirRepository("dir", dir)

		throw ArgErr("Repository not found: $repo")
	}
	
	private static File? toDir(Str dirPath) {
		file := FileUtils.toFile(dirPath)
		// trailing slashes aren't added to dir paths that don't exist
		if (file.exists.not)
			file = file.uri.plusSlash.toFile
		if (file.isDir)
			return file
		// todo does this ever return null?
		return null
	}
}
