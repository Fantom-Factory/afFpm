
internal const class FpmArgs {
	
	@Arg
	const Str	cmd			:= ""
	
	@Arg
	const Str	targetStr	:= ""	
	
	@Arg
	const Str[]	args		:= Str#.emptyList

	@Opt { aliases=["r"] }
	const Str	repo		:= ""
	
	@Opt { aliases=["o"] }
	const Bool	offline

	@Opt { aliases=["d"] }
	const Bool	debug

	@Opt { aliases=["js"] }
	const Bool	javascript

	new make(|This| f) { f(this) }
	
	Uri? target() {
		
		throw Err()
	}
	
	Repository repository(FpmConfig fpmConfig) {
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

