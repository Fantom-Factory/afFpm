
** FpmConfig is gathered from a hierarchy of 'fpm.props' files. These files are looked for in the following locations:
** 
** - '<FAN_HOME>/etc/afFpm/fpm.props'
** - '<WORK_DIR>/etc/afFpm/fpm.props'
** - './fpm.props'
** 
** Note that the config files are additive but the values are not. If all 3 files exist, then all 3 files are merged together, 
** with config values from a more specific file replacing (or overriding) values found in less specific one.
** 
** '<WORK_DIR>' may be specified with the 'FPM_ENV_PATH' environment variable. This means that **ALL** the config for FPM may 
** live outside of the Fantom installation. The only FPM file that needs to live in the Fantom installation is the 'afFpm.pod' 
** file itself.
** 
** Config may be removed by specifying an empty string as a value. For example, to remove the eggbox repository:
** 
**   fanrRepo.eggbox = 
** 
** Read the comments in the actual 'fpm.props' file itself for more details.
const class FpmConfig {

	** The directory used to resolve relative files.
	const File 		baseDir

	** The Fantom installation.
	const File 		homeDir

	** The temp directory.
	const File 		tempDir

	** A list of working directories.
	** The 'workDir' as returned by 'FpmEnv' is is always first item in this list.
	** 'homeDir' is always the last entry in the list, so it is never empty.
	const File[]	workDirs
	
	** A map of named directory repositories. These are essentially just dirs of pods. 
	const Str:File	dirRepos
	
	** A map of named fanr repositories, may be local or remote.
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
		configFilename := `fpm.props`
		
		// grab the config filename from an env var, but only if the version matches
		// this is useful for testing and development
		t1 := Env.cur.vars["FPM_CONFIG_FILENAME"]	// = fpm.props/2.0.1
		if (t1 != null) {
			t2 := Uri(t1, false)
			if (t2 != null) {
				t3 := t2.path
				if (t3.getSafe(0) == FpmEnv#.pod.version.toStr) {
					t4 := t3.getSafe(1)
					if (t4 != null) {
						t5 := Uri(t4, false)
						if (t5 != null)
							configFilename = t5
					}
				}
			}
		}
		
		baseDir = baseDir.normalize
		fpmFile := (File?) baseDir.plus(configFilename).normalize
		while (fpmFile != null && !fpmFile.exists)
			fpmFile = fpmFile.parent.parent?.plus(configFilename)

		// this is a little bit chicken and egg - we use the workDir to find fpm.props to find the workDir! 
		workDirs := "" as Str
		workDirs = (workDirs?.trimToNull == null ? "" : workDirs + File.pathSep) + (envPaths ?: "")
		workDirs = (workDirs?.trimToNull == null ? "" : workDirs + File.pathSep) + homeDir.osPath
		workFile := workDirs.split(File.pathSep.chars.first).exclude { it.isEmpty }.map { toRelDir(it, baseDir) + `etc/afFpm/` + configFilename }.unique as File[]
		if (fpmFile != null)
			workFile.insert(0, fpmFile)

		workFile = workFile.findAll { it.exists }

		fpmProps := Str:Str[:] { it.ordered = true }
		wokFiles := File[,]
		workFile.eachr {
			newProps := null as Str:Str
			try	newProps = it.readProps
			catch (Err err)
				FpmConfig#.pod.log.warn("Could not read ${it.normalize.osPath} ($err)")
			
			if (newProps["configCmd"] == "clearExisting") {
				// clearExisting should clear EVERYTHING! Let the new config define exactly what it needs
				wokFiles.clear
				fpmProps.clear
				envPaths = null
			}
			wokFiles.add(it)
			fpmProps.setAll(it.readProps)
		}

		return makeInternal(baseDir, homeDir, envPaths, fpmProps, wokFiles)
	}

	@NoDoc
	internal new makeInternal(File baseDir, File homeDir, Str? envPaths, Str:Str fpmProps, File[]? configFiles) {
		this.baseDir = baseDir = baseDir.normalize
		if (baseDir.isDir.not || baseDir.exists.not)
			throw ArgErr("Base directory is not valid: ${baseDir.osPath}")

		homeDir = homeDir.normalize
		if (homeDir.isDir.not || homeDir.exists.not)
			throw ArgErr("Home directory is not valid: ${homeDir.osPath}")

		this.homeDir = homeDir
		
		strInterpol := |Str? str->Str?| {
			if (str == null)
				return null
			// don't replace with osPath because it has a trailing slash on nix, but not on windows!
			if ((this.homeDir as File) != null)
				str = str.replace("\$fanHome", homeDir.uri.toStr).replace("\${fanHome}", homeDir.uri.toStr)
			if ((this.workDirs as File[]) != null)
				str = str.replace("\$workDir", workDirs.first.uri.toStr).replace("\${workDir}", workDirs.first.uri.toStr)
			if ((this.tempDir as File) != null)
				str = str.replace("\$tempDir", tempDir.uri.toStr).replace("\${tempDir}", tempDir.uri.toStr)
			return str
		}

		workDirs := strInterpol(fpmProps["workDirs"])
		workDirs = (workDirs?.trimToNull == null ? "" : workDirs + File.pathSep) + (envPaths ?: "")
		workDirs = (workDirs?.trimToNull == null ? "" : workDirs + File.pathSep) + homeDir.osPath.toStr
		this.workDirs = workDirs.split(File.pathSep.chars.first).exclude { it.isEmpty }.map { toRelDir(it, baseDir) }.unique
		
		tempDir := strInterpol(fpmProps["tempDir"])
		if (tempDir == null)
			tempDir = this.workDirs.first.plus(`temp/`, false).osPath.toStr
		this.tempDir = toRelDir(tempDir, baseDir)

		dirRepos := (Str:File) fpmProps.findAll |path, name| {
			name.startsWith("dirRepo.")
		}.keys.sort.reduce(Str:File[:] { ordered=true }) |Str:File repos, key| {
			path := fpmProps[key].trimToNull
			if (path == null) return repos	// allow config to be removed
			name := key["dirRepo.".size..-1]
			file := toRelDir(strInterpol(path.trim), baseDir)
			repos[name] = file
			return repos
		}

		fanrRepos := (Str:Uri) fpmProps.findAll |path, name| {
			name.startsWith("fanrRepo.") && !name.endsWith(".username") && !name.endsWith(".password")
		}.keys.sort.reduce(Str:Uri[:] { ordered=true }) |Str:Uri repos, key| {
			path := fpmProps[key].trimToNull
			if (path == null) return repos	// allow config to be removed
			name := key["fanrRepo.".size..-1]
			url  := Uri(path, false)

			if (url?.scheme != "http" && url?.scheme != "https")
				url = toRelDir(strInterpol(path.trim), baseDir).uri
			else
				if (url.userInfo != null) {
					userInfo := url.userInfo.split(':')
					repoName := key["fanrRepo.".size..-1]
					username := Uri.decodeToken(userInfo.getSafe(0) ?: "", Uri.sectionPath).trimToNull
					password := Uri.decodeToken(userInfo.getSafe(1) ?: "", Uri.sectionPath).trimToNull
					fpmProps["fanrRepo.${repoName}.username"] = username
					fpmProps["fanrRepo.${repoName}.password"] = password
					url		= url.toStr.replace("${url.userInfo}@", "").toUri
				}
			repos[name] = url
			return repos
		}

		// add workDirs to dirRepos (note the last dir is always fanHome, so ignore that one)
		if (this.workDirs.size > 1)
			if (!dirRepos.containsKey("workDir"))
				dirRepos["workDir"] = this.workDirs.first + `lib/fan/`
		if (this.workDirs.size > 2)
			this.workDirs.eachRange(1..<-1) |dir, i| {
				if (!dirRepos.containsKey("workDir[$i]"))
					dirRepos["workDir[$i]"] = dir + `lib/fan/`
			}
		
		// if not defined, add "fanHome" as a new directory repo
		// add fanHome last as these pods are _least_ important when resolving environment runtime pods
		if (!dirRepos.containsKey("fanHome"))
			dirRepos["fanHome"] = homeDir + `lib/fan/`
		
		// if "default" is not defined, set it to fanHome so FPM becomes a drop in replacement for fanr
		// this allows people to update their fanHome env by default
		if (!fanrRepos.containsKey("default") && !dirRepos.containsKey("default"))
			dirRepos["default"] = homeDir + `lib/fan/`

		// as Env is available to the entire FVM, be nice and remove any credentials
		// it's just lip service really, as anyone could re-read the fpm.config files
		rawConfig := fpmProps.exclude |val, key| { key.endsWith(".username") || key.endsWith(".password") }
		rawConfig = rawConfig.map |val, key| {
			userInfo := Uri(val, false)?.userInfo
			return userInfo == null ? val : val.replace("${userInfo}@", "")
		}

		both := dirRepos.keys.intersection(fanrRepos.keys)
		if (both.size > 0)
			throw Err("Repository '" + both.join(", ") + "' is defined as both a dirRepo AND a fanrRepo")

		// not sure if I want to cache them all here
//		allRepos := Str:Repository[:]
//		dirRepos .each |file, name| { allRepos[name] = LocalDirRepository(name, file) }
//		fanrRepos.each | url, name| { 
//			username := fpmProps["fanrRepo.${name}.username"]
//			password := fpmProps["fanrRepo.${name}.password"]
//			if (url.scheme == null   || url.scheme == "file")
//				allRepos[name] = LocalFanrRepository(name, url.toFile)
//			if (url.scheme == "http" || url.scheme == "https")
//				allRepos[name] = RemoteFanrRepository(name, url, username, password)
//		}

		this.dirRepos		= dirRepos
		this.fanrRepos		= fanrRepos
		this.launchPods 	= fpmProps["launchPods"]?.split(',') ?: Str#.emptyList
		this.configFiles	= configFiles ?: File[,]
		this.rawConfig		= rawConfig
		this._rawConfig		= fpmProps
	}

	** Returns a 'Repository' instance for the named repository. 
	** 'repoName' may be either a 'dirRepo' or a 'fanrRepo'. 
	Repository? repository(Str repoName, Str? username := null, Str? password := null) {
		
		if (dirRepos.containsKey(repoName))
			return LocalDirRepository(repoName, dirRepos[repoName])
		
		if (fanrRepos.containsKey(repoName)) {
			if (username == null)
				username = _rawConfig["fanrRepo.${repoName}.username"]
			if (password == null)
				password = _rawConfig["fanrRepo.${repoName}.password"]
			url := fanrRepos[repoName]
			if (url.scheme == null   || url.scheme == "file")
				return LocalFanrRepository(repoName, url.toFile)
			if (url.scheme == "http" || url.scheme == "https")
				return RemoteFanrRepository(repoName, url, username, password)
			throw ArgErr("Unknown scheme '${url.scheme}' in $url")
		}

		return null
	}
	
	** Returns a list of all repositories.
	** Note that some repositories may point to the same directory / URL.
	Repository[] repositories() {
		repos1 :=  dirRepos.keys.map { repository(it) }
		repos2 := fanrRepos.keys.map { repository(it) }
		// note that default, workDir, and fanHome may be the same
		return repos1.addAll(repos2)
	}

	** Dumps debug output to a string. The string will look similar to:
	** 
	** pre>
	** FPM Environment:
	**    Target Pod : afIoc 3.0+
	**      Base Dir : C:\
	**  Fan Home Dir : C:\Apps\fantom-1.0.70
	**     Work Dirs : C:\Repositories\Fantom
	**                 C:\Apps\fantom-1.0.70
	**      Temp Dir : C:\Repositories\Fantom\temp
	**  Config Files : C:\Apps\fantom-1.0.70\etc\afFpm\config.props
	** 
	**     Dir Repos :
	**       workDir = C:\Repositories\Fantom
	**       fanHome = C:\Apps\fantom-1.0.70/lib/fan/
	** 
	**    Fanr Repos :
	**       default = C:\Repositories\Fantom\repo-default
	**        eggbox = http://eggbox.fantomfactory.org/fanr/
	**       release = C:\Repositories\Fantom\repo-release
	**       repo302 = http://repo.status302.com/fanr/
	** <pre
	Str dump() {
		str := ""
		str += "      Base Dir : " + dumpList([baseDir])
		str += "  Fan Home Dir : " + dumpList([homeDir])
		str += "     Work Dirs : " + dumpList(workDirs)
		str += "      Temp Dir : " + dumpList([tempDir])
		str += "  Config Files : " + dumpList(configFiles)

		if (dirRepos.size > 0) str += "\n"
		str += "     Dir Repos : " + (dirRepos.isEmpty ? "(none)" : "") + "\n"
		maxDir := dirRepos.keys.reduce(14) |Int size, repoName| { size.max(repoName.size) } as Int
		dirRepos.each |repoFile, repoName| {
			exists := repoFile.exists ? "" : " (does not exist)"
			str += repoName.justr(maxDir) + " = " + repoFile.osPath + exists + "\n"
		}

		if (fanrRepos.size > 0) str += "\n"
		str += "    Fanr Repos : " + (fanrRepos.isEmpty ? "(none)" : "") + "\n"
		maxDir = fanrRepos.keys.reduce(14) |Int size, repoName| { size.max(repoName.size) } as Int
		fanrRepos.each |repoUrl, repoName| {
			usr	:= repoUrl.userInfo == null ? "" : repoUrl.userInfo + "@"
			url	:= repoUrl.toStr.replace(usr, "")
			str += repoName.justr(maxDir) + " = " + url + "\n"
		}

		return str
	}

	private Str dumpList(File[] files) {
		if (files.isEmpty)
			return "(none)\n"

		ext := files.first.exists ? "" : " (does not exist)"
		str := "${files.first.osPath}${ext}\n"
		if (files.size > 1)
			files[1..-1].each {
				exists := it.exists ? "" : " (does not exist)"
				str += "".justr(14) + "   ${it.osPath}${exists}\n"
			}
		return str
	}
	
	private static File toRelDir(Str dirPath, File baseDir) {
		FileUtils.toAbsDir(dirPath, baseDir)
	}
}
