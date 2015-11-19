
const class FpmConfig {
	
	const File 		homeDir

	const File 		repoDir

	const File 		tempDir

	const File 		workDir
	
	const File[]	paths

	static new make() {
		makeFromDirs(File(``), Env.cur.homeDir, Env.cur.vars["FAN_ENV_PATH"])
	}
	
	@NoDoc	// ctor used by F4
	new makeFromDirs(File baseDir, File homeDir, Str? envPaths) {
		baseDir = baseDir.normalize
		if (baseDir.isDir.not || baseDir.exists.not)
			throw ArgErr("Base directory is not valid: ${baseDir.osPath}")

		homeDir = homeDir.normalize
		if (homeDir.isDir.not || homeDir.exists.not)
			throw ArgErr("Home directory is not valid: ${homeDir.osPath}")

		this.homeDir = homeDir

		fpmFile := (File?) baseDir.plus(`fpm.props`).normalize
		while (fpmFile != null && !fpmFile.exists)
			fpmFile = fpmFile.parent.parent?.plus(`fpm.props`)
		fpmProps := fpmFile?.readProps ?: Str:Str[:]
		
		workDir := fpmProps["workDir"]
		if (workDir == null)
			workDir = podProp("workDir")
		if (workDir == null)
			workDir = envPaths?.split(File.pathSep.chars.first)?.first
		if (workDir == null)
			workDir = homeDir.uri.toStr
		this.workDir = toFile(baseDir, workDir)
		
		repoDir := fpmProps["repoDir"]
		if (repoDir == null)
			repoDir = podProp("repoDir")
		if (repoDir == null)
			repoDir = this.workDir.plus(`repo/`, false).uri.toStr
		this.repoDir = toFile(baseDir, repoDir)
		
		tempDir := fpmProps["tempDir"]
		if (tempDir == null)
			tempDir = podProp("tempDir")
		if (tempDir == null)
			tempDir = this.workDir.plus(`temp/`, false).uri.toStr
		this.tempDir = toFile(baseDir, tempDir)
		
		paths := envPaths?.split(File.pathSep.chars.first) ?: Str#.emptyList
		paths.insert(0, workDir)
		paths.add(homeDir.osPath)
		this.paths = paths.map { toFile(baseDir, it) }.unique
	}
	
	private File toFile(File baseDir, Str filePath) {
		file := filePath.startsWith("file:") ? File(filePath.toUri, false) : File.os(filePath)
		if (file.uri.isPathAbs.not)
			file = baseDir + file.uri
		return file.normalize
	}
	
	private Str? podProp(Str key) {
		// recursing into Env.cur while still creating an Env can cause problems
		// mainly with 'fan -pods'
		try return Env.cur.config(typeof.pod, "repoDir")
		catch return null
	}
}
