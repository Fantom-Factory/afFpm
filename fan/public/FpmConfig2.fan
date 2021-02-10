
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
const class FpmConfig2 {

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

	** The 'fpm.props' files used to generate this class.
	const File[]	configFiles

	** The macros applied to repository paths.
	const Str:Str	macros

	** The properties gleaned from the 'configFiles' (after macros have been applied).
	const Str:Str	props

	@NoDoc
	static new make() {
		makeFromDirs(File(`./`), Env.cur.homeDir, Env.cur.vars["FAN_ENV_PATH"])
	}

	@NoDoc
	static new makeFromDirs(File baseDir, File homeDir, Str? envPaths) {
		baseDir = baseDir.normalize
		homeDir = homeDir.normalize

		// grab the config filename from an env var, but only if the version matches
		// this is useful for testing and development
		configFilename := `fpm.props`
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
		
		// find all fpm.props in parent directories
		fpmFiles := File[,]
		fpmFile2	 := (File?) baseDir.plus(configFilename)
		while (fpmFile2 != null) {
			if (fpmFile2.exists)
				fpmFiles.add(fpmFile2)
			fpmFile2 = fpmFile2.parent.parent?.plus(configFilename)
		}

		// this is a little bit chicken and egg - we use the workDir to find fpm.props to find the workDir! 
		workStrs := StrBuf()
		workStrs.join(envPaths ?: "", File.pathSep)
		workStrs.join(homeDir.osPath, File.pathSep)
		workStrs.toStr.split(File.pathSep.chars.first).exclude { it.isEmpty }.each |workDir| {
			file := toRelDir(workDir, baseDir) + `etc/afFpm/` + configFilename
			if (file.exists)
				fpmFiles.add(file)
		}


		
		fpmProps := Str:Str[:] { it.ordered = true }
		wokFiles := File[,]
		workFile.eachr {
			newProps := null as Str:Str
			try	newProps = it.readProps
			catch (Err err)
				FpmConfig#.pod.log.warn("Could not read ${it.normalize.osPath} ($err)")
			
			if (newProps["clear.all"] != null || newProps["configCmd"] == "clearExisting") {
				// clearExisting should clear EVERYTHING! Let the new config define exactly what it needs
				wokFiles.clear
				fpmProps.clear
				envPaths = null
			}
			
			newProps.each |val, key| {
				if (key.startsWith("clear.") && key != "clear.all") {
					rem := key["clear.".size..-1]
					fpmProps = fpmProps.exclude |v, k| { k.startsWith(rem + ".")  }
				}
			}

			wokFiles.add(it)
			fpmProps.setAll(newProps)
		}

//		macros		:= Str:Str[:]			{ it.ordered = true }
//		tempDir		:= (File)  (fpmProps.eachrWhile	{ it.tempDir  }	?: homeDir + `temp/`)
//		workDirs	:= (File[]) fpmProps.flatMap	{ it.workDirs }
//		workDir		:= (File)  (workDirs.first		?: homeDir)
//
//		// don't replace with osPath because it has a trailing slash on nix, but not on windows!
//		macros["fanHome"] = homeDir.uri.toStr
//		macros["tempDir"] = tempDir.uri.toStr
//		macros["workDir"] = workDir.uri.toStr
//
//		fpmProps.each |props| {
//			// TODO add prefex to each() ???
//			props.each |value, name| {
//				if (name.startsWith("macro."))
//					macros[name["macro.".size..-1]] = value
//			}
//		}

		return makeInternal(baseDir, homeDir, fpmProps)
	}

	** 'fpmProps' has the least significant first, so it may be overridden by the later entries.
	@NoDoc
	internal new makeInternal(File baseDir, File homeDir, FpmProps[] fpmProps) {
		homeDir = homeDir.normalize
		if (homeDir.isDir.not || homeDir.exists.not)
			throw ArgErr("Home directory is not valid: ${homeDir.osPath}")

		tempDir		:= (File)  (fpmProps.eachrWhile	{ it.tempDir	} ?: homeDir + `temp/`)
		workDirs	:= (File[]) fpmProps.flatMap	{ it.workDirs	}.unique
		launchPods	:= (Str[])  fpmProps.flatMap	{ it.launchPods }.unique
		workDir		:= (File)  (workDirs.first		?: homeDir)

		dirRepos	:= Str:File[:] { it.ordered = true }
		fpmProps.each |props| { dirRepos.setAll(props.dirRepos) }

		fanrRepos	:= Str:Uri[:] { it.ordered = true }
		fpmProps.each |props| { fanrRepos.setAll(props.fanrRepos) }

		allProps	:= Str:Str[:]
		fpmProps.each |props| { allProps.setAll(props.props) }

		allMacros	:= Str:Str[:]
		fpmProps.each |props| { allMacros.setAll(props.macros) }

		// add workDirs to dirRepos (note the last dir is always fanHome, so ignore that one)
		if (workDirs.size > 1)
			if (!dirRepos.containsKey("workDir"))
				dirRepos["workDir"] = workDirs.first + `lib/fan/`
		if (workDirs.size > 2)
			workDirs.eachRange(1..<-1) |dir, i| {
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

		both := dirRepos.keys.intersection(fanrRepos.keys)
		if (both.size > 0)
			throw Err("Repository '" + both.join(", ") + "' is defined as both a dirRepo AND a fanrRepo")

		this.baseDir		= baseDir
		this.homeDir		= homeDir
		this.tempDir		= tempDir
		this.workDirs		= workDirs
		this.dirRepos		= dirRepos
		this.fanrRepos		= fanrRepos
		this.launchPods 	= launchPods
		this.configFiles	= fpmProps.map { it.file }
		this.macros			= allMacros
		this.props			= allProps
	}
	
	** Returns a 'Repository' instance for the named repository. 
	** 'repoName' may be either a 'dirRepo' or a 'fanrRepo'. 
	Repository? repository(Str repoName, Str? username := null, Str? password := null) {
		
		if (dirRepos.containsKey(repoName))
			return LocalDirRepository(repoName, dirRepos[repoName])
		
		if (fanrRepos.containsKey(repoName)) {
			if (username == null)
				username = props["fanrRepo.${repoName}.username"]
			if (password == null)
				password = props["fanrRepo.${repoName}.password"]
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

		str += "\n"
		str += "     Dir Repos : " + (dirRepos.isEmpty ? "(none)" : "") + "\n"
		max := dirRepos.keys.reduce(14) |Int size, name| { size.max(name.size) } as Int
		dirRepos.each |file, name| {
			exists := file.exists ? "" : " (does not exist)"
			str += name.justr(max) + " = ${file.osPath}${exists}\n"
		}

		str += "\n"
		str += "    Fanr Repos : " + (fanrRepos.isEmpty ? "(none)" : "") + "\n"
		max = fanrRepos.keys.reduce(14) |Int size, name| { size.max(name.size) } as Int
		fanrRepos.each |repoUrl, name| {
			usr		:= repoUrl.userInfo == null ? "" : repoUrl.userInfo + "@"
			url		:= repoUrl.toStr.replace(usr, "")
			exists	:= (repoUrl.scheme == "file" && repoUrl.toFile.exists) ? "" : " (does not exist)"
			str += name.justr(max) + " = ${url}${exists}\n"
		}

		str += "\n"
		str += "        Macros : " + (macros.isEmpty ? "(none)" : "") + "\n"
		max = macros.keys.reduce(14) |Int size, name| { size.max(name.size) } as Int
		macros.each |value, name| {
			str += name.justr(max) + " = ${value}\n"
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
