
const class FpmConfig {
	
	const File 		workDir

	const File 		tempDir

	const File 		repoDir
	
	const File[]	paths
	
	new make() {
		fpmFile := (File?) File(`fpm.props`).normalize
		while (fpmFile != null && !fpmFile.exists)
			fpmFile = fpmFile.parent.parent?.plus(`fpm.props`)
		fpmProps := fpmFile?.readProps ?: Str:Str[:]
		
		workDir := fpmProps["workDir"]
		if (workDir == null)
			workDir = podProp("workDir")
		if (workDir == null)
			workDir = Env.cur.vars["FAN_ENV_PATH"]?.split(File.pathSep.chars.first)?.first
		if (workDir == null)
			workDir = Env.cur.homeDir.uri.toStr
		this.workDir = toFile(workDir)
		
		repoDir := fpmProps["repoDir"]
		if (repoDir == null)
			repoDir = podProp("repoDir")
		if (repoDir == null)
			repoDir = this.workDir.plus(`repo/`, false).uri.toStr
		this.repoDir = toFile(repoDir)
		
		tempDir := fpmProps["tempDir"]
		if (tempDir == null)
			tempDir = podProp("tempDir")
		if (tempDir == null)
			tempDir = this.workDir.plus(`temp/`, false).uri.toStr
		this.tempDir = toFile(tempDir)
		
		paths := Env.cur.vars["FAN_ENV_PATH"]?.split(File.pathSep.chars.first) ?: Str#.emptyList
		paths.insert(0, workDir)
		paths.add(Env.cur.homeDir.osPath)
		this.paths = paths.map { toFile(it) }.unique
	}
	
	private File toFile(Str filePath) {
		filePath.startsWith("file:") ? File(filePath.toUri, false) : File.os(filePath)
	}
	
	private Str? podProp(Str key) {
		// recursing into Env.cur while still creating an Env can cause problems
		// mainly with 'fan -pods'
		try return Env.cur.config(typeof.pod, "repoDir")
		catch return null
	}
}
