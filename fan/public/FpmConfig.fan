using fanr

** Represents configuration as parsed from a hierarchy of 'fpm.props' files.
const class FpmConfig {
	private static const Log 	log := FpmConfig#.pod.log

	** The Fantom installation.
	const File 		homeDir

	** The temp directory.
	const File 		tempDir

	** A list of working directories.
	** The 'workDir' as returned by 'FpmEnv' is is always first item in this list.
	** 'homeDir' is always the last entry in the list, so it is never empty.
	const File[]	workDirs
	
	** A list of directories where pods are picked up from.
	const File[]	podDirs
	
	** A map of named local file system repositories.
	const Str:File 	fileRepos

	** A map of named remote fanr repositories.
	const Str:Uri	fanrRepos
	
	** A list of libraries used to launch applications
	const Str[]		launchPods

	** The config files used to generate this class.
	const File[]	configFiles

	** The raw FPM config gleaned from the 'configFiles'.
	** Does not include fanr credentials.
	const Str:Str	rawConfig

	private const Str:Str	_rawConfig

	private new makePrivate(|This|in) { in(this) }
	
	@NoDoc
	static new make() {
		makeFromDirs(File(`./`), Env.cur.homeDir, Env.cur.vars["FAN_ENV_PATH"])
	}

	@NoDoc
	static new makeFromDirs(File baseDir, File homeDir, Str? envPaths) {
		fpmFile := (File?) baseDir.plus(`fpm.props`).normalize
		while (fpmFile != null && !fpmFile.exists)
			fpmFile = fpmFile.parent.parent?.plus(`fpm.props`)

		// this is a little bit chicken and egg - we use the workDir to find config.props to find the workDir! 
		workDirs := "" as Str
		workDirs = (workDirs?.trimToNull == null ? "" : workDirs + File.pathSep) + (envPaths ?: "")
		workDirs = (workDirs?.trimToNull == null ? "" : workDirs + File.pathSep) + homeDir.uri.toStr
		workFile := workDirs.split(File.pathSep.chars.first).map { toAbsDir(it) + `etc/afFpm/fpm.props` }.unique as File[]
		if (fpmFile != null)
			workFile.insert(0, fpmFile)
		workFile = workFile.findAll { it.exists }

		fpmProps := Str:Str[:] { it.ordered = true }
		workFile.eachr { fpmProps.setAll(it.readProps) }

		return makeInternal(baseDir, homeDir, envPaths, fpmProps, workFile.reverse)
	}

	@NoDoc
	internal new makeInternal(File baseDir, File homeDir, Str? envPaths, Str:Str fpmProps, File[]? configFiles) {
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

		repoDirs := (Str:File) fpmProps.findAll |path, name| {
			name.startsWith("fileRepo.")
		}.reduce(Str:File[:] { ordered=true }) |Str:File repos, Str path, name| {
			repos[name["fileRepo.".size..-1]] = toAbsDir(path.trim)
			return repos
		}
		if (repoDirs.containsKey("default").not)
			repoDirs["default"] = this.workDirs.first.plus(`fpmRepo-default/`, false)
		this.fileRepos = repoDirs
		
		tempDir := fpmProps["tempDir"]
		if (tempDir == null)
			tempDir = this.workDirs.first.plus(`temp/`, false).uri.toStr
		this.tempDir = toAbsDir(tempDir)

		podDirs := fpmProps["podDirs"]
		this.podDirs = podDirs?.split(File.pathSep.chars.first)?.map { toRelDir(baseDir, it) }?.findAll |File dir->Bool| { dir.exists }?.unique ?: File#.emptyList

		fanrRepos := (Str:Uri) fpmProps.findAll |path, name| {
			name.startsWith("fanrRepo.") && name.endsWith(".username").not && name.endsWith(".password").not
		}.reduce(Str:Uri[:] { ordered=true }) |Str:Uri repos, Str path, key| {
			url  := path.trim.toUri
			name := key["fanrRepo.".size..-1]
			if (url.scheme != "http" && url.scheme != "https")
				throw Err("Invalid URI scheme for fanr repo '${name}', only http and https permitted: ${url}")
			repos[name] = url
			return repos
		}
		this.fanrRepos		= fanrRepos
		
		this.launchPods 	= fpmProps["launchPods"]?.split(',') ?: Str#.emptyList
		
		this.configFiles	= configFiles ?: File[,]
		
		this._rawConfig		= fpmProps
		
		// as Env is available to the entire FVM, be nice and remove any credentials
		// it's just lip service really, as anyone could re-read the fpm.config files
		this.rawConfig		= fpmProps.exclude |val, key| { key.endsWith(".username") || key.endsWith(".password") }
	}
	
	** Returns a fanr 'Repo' instance for the named repository. 
	** May be either a 'fileRepo' or a 'fanrRepo'. 
	** 
	** 'username' and 'password' are only used if a 'fanrRepo' is returned.
	Repo fanrRepo(Str repoName, Str? username := null, Str? password := null) {
		// FPM doesn't need / use a local fanr repo, but others may find it useful
		if (fileRepos.containsKey(repoName))
			return Repo.makeForUri(fileRepos[repoName].uri)
		
		if (fanrRepos.containsKey(repoName)) {
			if (username == null)
				username = _rawConfig["fanrRepo.${repoName}.username"]
			if (password == null)
				password = _rawConfig["fanrRepo.${repoName}.password"]
			return toFanrRepo(fanrRepos[repoName], username, password)
		}
		
		allRepoNames := fileRepos.keys.addAll(fanrRepos.keys).sort
		throw ArgErr("Cound not find remote repo with name '${repoName}'. Available repos: " + allRepoNames.join(","))
	}

	** Dumps debug output to a string. The string will look similar to:
	** 
	** pre>
	** FPM Environment:
	** 
	**    Target Pod : shStackHubAdmin 0+
	**      Home Dir : C:\Apps\fantom-1.0.68
	**     Work Dirs : C:\Repositories\Fantom, C:\Apps\fantom-1.0.68
	**      Pod Dirs : C:\Projects\StackHub\stackhub-admin\lib
	**      Temp Dir : C:\Repositories\Fantom\temp
	**  Config Files : C:\Apps\fantom-1.0.68\etc\afFpm\config.props
	**    File Repos :
	**       default = C:\Repositories\Fantom\repo-default
	**       release = C:\Repositories\Fantom\repo-release
	**    Fanr Repos :
	** fantomFactory = http://pods.fantomfactory.org/fanr/
	**       repo302 = http://repo.status302.com/fanr/
	** <pre
	Str dump() {
		str := ""
		str += "      Home Dir : ${homeDir.osPath}\n"
		str += "     Work Dirs : " + dumpList(workDirs)
		str += "      Pod Dirs : " + dumpList(podDirs)
		str += "      Temp Dir : ${tempDir.osPath}\n"
		str += "  Config Files : " + dumpList(configFiles)

		if (fileRepos.size > 0)
			str += "\n"
		str += "    File Repos : " + (fileRepos.isEmpty ? "(none)" : "") + "\n"
		maxDir := fileRepos.keys.reduce(14) |Int size, repoName| { size.max(repoName.size) } as Int
		fileRepos.each |repoDir, repoName| {
			str += repoName.justr(maxDir) + " = " + repoDir.osPath + "\n"
		}

		if (fanrRepos.size > 0)
			str += "\n"
		str += "    Fanr Repos : " + (fanrRepos.isEmpty ? "(none)" : "") + "\n"
		maxDir = fanrRepos.keys.reduce(14) |Int size, repoName| { size.max(repoName.size) } as Int
		fanrRepos.each |repoUrl, repoName| {
			usr	:= repoUrl.userInfo == null ? "" : repoUrl.userInfo + "@"
			// Fantom Str.replace() bug - see http://fantom.org/forum/topic/2413
			url	:= usr.isEmpty ? repoUrl.toStr : repoUrl.toStr.replace(usr, "")
			str += repoName.justr(maxDir) + " = " + url + "\n"
		}

		return str
	}

	private Str dumpList(File[] files) {
		if (files.isEmpty)
			return "(none)\n"

		str := "${files.first.osPath}\n"
		if (files.size > 1)
			files[1..-1].each {
				str += "".justr(14) + "   ${it.osPath}\n"
			}
		return str
	}

	internal static Repo toFanrRepo(Uri url, Str? usr := null, Str? pwd := null) {
		userStr	 := url.userInfo == null ? "" : url.userInfo + "@"
		repoUrl	 := url.toStr.replace(userStr, "").toUri
		// TODO do proper percent decoding
		username := Uri.decode(url.userInfo?.split(':')?.getSafe(0)?.replace("%40", "@") ?: "").toStr.trimToNull	// decode percent encoding
		password := Uri.decode(url.userInfo?.split(':')?.getSafe(1)?.replace("%40", "@") ?: "").toStr.trimToNull
		if (usr != null)	username = usr
		if (pwd != null)	password = pwd
		return Repo.makeForUri(repoUrl, username, password)
	}
	
	private static File toAbsDir(Str dirPath) {
		FileUtils.toAbsDir(dirPath)
	}
	
	private static File toRelDir(File baseDir, Str dirPath) {
		FileUtils.toRelDir(baseDir, dirPath)
	}
}
