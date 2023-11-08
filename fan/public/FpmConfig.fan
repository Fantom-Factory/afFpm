
** FpmConfig is gathered from a hierarchy of 'fpm.props' files. These files are looked for in the following locations:
** 
** - '<FAN_HOME>/etc/afFpm/fpm.props'
** - '<WORK_DIR>/etc/afFpm/fpm.props'
** - './fpm.props'
** - './../fpm.props'
** - './../../fpm.props' *(...and so on...)*
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
	
	** A list of extra pods to be resolved alongside the target pod.
	const Depend[]	extraPods

	** A list of libraries used to launch applications
	const Str[]		launchPods
	
	** The 'fpm.props' files used to generate this class.
	const File[]	configFiles

	** The macros applied to repository paths.
	const Str:Str	macros

	** The properties gleaned from the 'configFiles' (after macros have been applied).
	const Str:Str	props

	private static const Str _pathSepStr	:= ";"
	private static const Int _pathSepInt	:= ';'
	
	@NoDoc
	static new make() {
		fromDirs(File(`./`), Env.cur.homeDir, Env.cur.vars["FAN_ENV_PATH"])
	}

	** This ctor used by f4afFpm::FpmCompileEnv
	@NoDoc
	static new fromDirs(File baseDir, File homeDir, Str? fanEnvPath) {
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
		curFile2 := (File?) baseDir.plus(configFilename)
		while (curFile2 != null) {
			if (curFile2.exists)
				fpmFiles.add(curFile2)
			curFile2 = curFile2.parent.parent?.plus(configFilename)
		}

		// this is a little bit chicken and egg - we use the workDir to find fpm.props to find the workDir! 
		workStrs := StrBuf()
		workStrs.join(fanEnvPath?.replace(File.pathSep, _pathSepStr) ?: "", _pathSepStr)
		workStrs.join(homeDir.osPath, _pathSepStr)
		workStrs.toStr.split(_pathSepInt).exclude { it.isEmpty }.each |workDir| {
			file := toRelDir(workDir, baseDir) + `etc/afFpm/` + configFilename
			if (file.exists)
				fpmFiles.add(file)
		}

		// convert files to RawProps
		rawProps := null as RawProps
		fpmFiles.unique.reverse.each |fpmFile| {
			rawProps = RawProps(fpmFile.readProps, fpmFile, rawProps)
		}
		
		// cater for having NO fpm.prop files (which may well happen!)
		if (rawProps == null)
			rawProps = RawProps.defVal
		
		return makeFromProps(rawProps, baseDir, homeDir, fanEnvPath)
	}

	** 'fpmProps' has the least significant first, so it may be overridden by the later entries.
	@NoDoc
	internal new makeFromProps(RawProps rawProps, File baseDir, File homeDir, Str? fanEnvPath := null) {
		homeDir = homeDir.normalize
		if (homeDir.isDir.not || homeDir.exists.not)
			throw ArgErr("Home directory is not valid: ${homeDir.osPath}")

		baseDir = baseDir.normalize
		if (baseDir.isDir.not || baseDir.exists.not)
			throw ArgErr("Base directory is not valid: ${baseDir.osPath}")

		macros		:= rawProps.allMacros
		macros["baseDir"] = baseDir.uri.toStr
		macros["fanHome"] = homeDir.uri.toStr

		// todo - maybe add a second round of macro replacement here for workDirs?
		
		allProps	:= rawProps.allProps.map |pval, pkey| {
			macros.each |mval, mkey| { pval = pval.replace("\${${mkey}}", mval) }
			return pval
		}
		fpmProps	:= FpmProps(allProps)
		tempDir		:= rawProps.toRelDir("tempDir", fpmProps.tempDir) ?: homeDir + `temp/`
		workDirs	:= fpmProps.workDirs .map |dir     ->File?|	{ rawProps.toRelDir("workDirs", dir)			}.exclude { it == null } as File[]
		dirRepos	:= fpmProps.dirRepos .map |dir, key->File?|	{ rawProps.toRelDir("dirRepo.${key}", dir)		}.exclude { it == null } as Str:File
		fanrRepos	:= fpmProps.fanrRepos.map |dir, key->Uri? |	{
			url  := Uri(dir, false)
			if (url != null && (url.scheme == "http" || url.scheme == "https"))
				return url
			return rawProps.toRelDir("fanrRepo.${key}", dir)?.uri
		}.exclude { it == null } as Str:Uri

		// add FAN_ENV_PATH dirs to workDirs
		if (fanEnvPath != null)
			fanEnvPath.trim.split(File.pathSep.chars.first).each |workDir| {
				if (workDir.size > 0)
					workDirs.add(toRelDir(workDir, baseDir))
			}

		// add workDirs to dirRepos
		if (workDirs.size > 0)
			if (!dirRepos.containsKey("workDir"))
				dirRepos["workDir"] = workDirs.first + `lib/fan/`
		if (workDirs.size > 1)
			workDirs.eachRange(1..-1) |dir, i| {
				if (!dirRepos.containsKey("workDir[$i]"))
					dirRepos["workDir[$i]"] = dir + `lib/fan/`
			}

		// workDirs should always have fanHome as a backup
		workDirs.add(homeDir)
		
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
		this.extraPods		= fpmProps.extraPods
		this.launchPods 	= fpmProps.launchPods
		this.configFiles	= rawProps.files.unique
		this.props			= allProps
		this.macros			= macros
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
		str += "      Base Dir : " + dumpFiles([baseDir])
		str += "  Fan Home Dir : " + dumpFiles([homeDir])
		str += "     Work Dirs : " + dumpFiles(workDirs)
		str += "      Temp Dir : " + dumpFiles([tempDir])
		str += "    Extra Pods : " + dumpList(extraPods)
		str += "  Config Files : " + dumpFiles(configFiles)

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
			exists	:= (repoUrl.scheme == "file" && repoUrl.toFile.exists == false) ? " (does not exist)" : ""
			str += name.justr(max) + " = ${url}${exists}\n"
		}

		// I've got too many Macros for this to still be useful 
//		str += "\n"
//		str += "        Macros : " + (macros.isEmpty ? "(none)" : "") + "\n"
//		max = macros.keys.reduce(14) |Int size, name| { size.max(name.size) } as Int
//		macros.each |value, name| {
//			str += name.justr(max) + " = ${value}\n"
//		}

		return str
	}

	private Str dumpFiles(File[] files) {
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

	private Str dumpList(Obj[] objs) {
		if (objs.isEmpty)
			return "(none)\n"

		str := "${objs.first}\n"
		if (objs.size > 1)
			objs[1..-1].each {
				str += "".justr(14) + "   ${it}\n"
			}
		return str
	}

	private static File toRelDir(Str dirPath, File base) {
		FileUtils.toAbsDir(dirPath, base)
	}
}
