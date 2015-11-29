
const class FpmConfig {
	private static const Log 	log := FpmConfig#.pod.log

	const File 		homeDir

	const Str:File 	repoDirs

	const File 		tempDir

	** homeDir is always the last entry, so this list is never empty
	const File[]	workDirs
	
	const File[]	podDirs

	private new makePrivate(|This|in) { in(this) }
	
	static new make() {
		makeFromDirs(File(``), Env.cur.homeDir, Env.cur.vars["FAN_ENV_PATH"])
	}

	@NoDoc	// ctor used by F4
	static new makeFromDirs(File baseDir, File homeDir, Str? envPaths) {
		fpmFile := (File?) baseDir.plus(`fpm.props`).normalize
		while (fpmFile != null && !fpmFile.exists)
			fpmFile = fpmFile.parent.parent?.plus(`fpm.props`)

		// this is a little bit chicken and egg - we use the workDir to find config.props to find the workDir! 
		workDirs := "" as Str
		workDirs = (workDirs?.trimToNull == null ? "" : workDirs + File.pathSep) + (envPaths ?: "")
		workDirs = (workDirs?.trimToNull == null ? "" : workDirs + File.pathSep) + homeDir.uri.toStr
		workFile := workDirs.split(File.pathSep.chars.first).map { toAbsDir(it) + `etc/afFpm/config.props` }.unique as File[]
		if (fpmFile != null)
			workFile.insert(0, fpmFile)

		fpmProps := Str:Str[:] { it.ordered = true }
		workFile.eachr { if (it.exists) fpmProps.setAll(it.readProps) }

		return makeInternal(baseDir, homeDir, envPaths, fpmProps)
	}

	@NoDoc	// ctor used by tests
	internal new makeInternal(File baseDir, File homeDir, Str? envPaths, Str:Str fpmProps) {
		baseDir = baseDir.normalize
		if (baseDir.isDir.not || baseDir.exists.not)
			throw ArgErr("Base directory is not valid: ${baseDir.osPath}")

		homeDir = homeDir.normalize
		if (homeDir.isDir.not || homeDir.exists.not)
			throw ArgErr("Home directory is not valid: ${homeDir.osPath}")

		this.homeDir = homeDir
		
		workDirs := fpmProps["workDirs"]
		workDirs = (workDirs?.trimToNull == null ? "" : workDirs + File.pathSep) + (envPaths ?: "")
		workDirs = (workDirs?.trimToNull == null ? "" : workDirs + File.pathSep) + homeDir.uri.toStr
		this.workDirs = workDirs.split(File.pathSep.chars.first).map { toAbsDir(it) }.unique

		repoDirs := (Str:Str) fpmProps.findAll |path, name| {
			name.startsWith("repoDir.")
		}.reduce(Str:Str[:]) |Str:Str repos, path, name| {
			repos[name["repoDir.".size..-1]] = path
			return repos
		}
		if (repoDirs.containsKey("default").not)
			repoDirs["default"] = this.workDirs.first.plus(`repo/`, false).uri.toStr
		this.repoDirs = repoDirs.map { toAbsDir(it) }
		
		tempDir := fpmProps["tempDir"]
		if (tempDir == null)
			tempDir = this.workDirs.first.plus(`temp/`, false).uri.toStr
		this.tempDir = toAbsDir(tempDir)
		
		podDirs := fpmProps["podDirs"]
		this.podDirs = podDirs?.split(File.pathSep.chars.first)?.map { toRelDir(baseDir, it) }?.unique ?: File#.emptyList
	}
	
	Str debug() {
		str := ""
		str += "Home Dir   : ${homeDir.osPath}\n"
		str += "Work Dirs  : " + workDirs.join(", ") { it.osPath } + "\n"
		str += "Pod  Dirs  : " + podDirs .join(", ") { it.osPath } + "\n"
		str += "Temp Dir   : ${tempDir.osPath}\n"
		str += "Repo Dirs  : -\n"

		maxDir := repoDirs.keys.reduce(10) |Int size, repoName| { size.max(repoName.size) } as Int
		repoDirs.each |repoDir, repoName| {
			str += repoName.justr(maxDir) + " = " + repoDir.osPath + "\n"
		}

		return str
	}

	private static File toAbsDir(Str dirPath) {
		dir := toDir(dirPath).normalize
		if (dir.uri.isPathAbs.not)
			throw ArgErr("Directory path must be absolute: ${dirPath}")
		return dir
	}
	
	private static File toRelDir(File baseDir, Str dirPath) {
		dir := toDir(dirPath)
		if (dir.uri.isPathAbs.not)
			dir = baseDir + dir.uri
		return dir.normalize
	}

	private static File toDir(Str dirPath) {
		file := dirPath.startsWith("file:") && dirPath.containsChar('\\').not ? File(dirPath.toUri, false) : File.os(dirPath)
		if (file.isDir.not)
			throw ArgErr("Path is not a directory: ${dirPath} (${file.normalize.osPath})")
		return file
	}
}
