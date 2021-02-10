
** 'RawProps' provides properties from an 'fpm.props' file, after performing a little pre-processing.
** Such as:
**  - extracting any 'macro' properties
**  - splitting user info from fanrRepo URLs into '.username' and '.password' properties
**  
const class RawProps {
	
	** The 'fpm.props' file this instance represents.
	const File		file

	** The raw properties contained within the 'fpm.props'.
	const Str:Str	props

	** The macros found in 'fpm.props'.
	const Str:Str	macros

	new make(File propsFile) {
		propsFile = propsFile.normalize
		if (propsFile.isDir || propsFile.exists.not)
			throw ArgErr("Props file is not valid: ${propsFile.osPath}")

		props	:= propsFile.readProps
		macros	:= Str:Str[:] { it.ordered = true }
		props.each |value, name| {
			if (name.startsWith("macro."))
				macros[name["macro.".size..-1]] = value
		}

		// split out user info from fanrRepo URLs into '.username' and '.password' properties
		props.keys.findAll |key| {
			key.startsWith("fanrRepo.") && !key.endsWith(".username") && !key.endsWith(".password")
		}.each |key| {
			path := props[key].trimToNull
			if (path == null) return		// empty string may be removing config

			name := key["fanrRepo.".size..-1]
			url  := Uri(path, false)

			if (url?.userInfo != null) {
				userInfo := url.userInfo.split(':')
				repoName := key["fanrRepo.".size..-1]
				userkey	 := "fanrRepo.${repoName}.username"
				passkey	 := "fanrRepo.${repoName}.password"
				username := Uri.decodeToken(userInfo.getSafe(0) ?: "", Uri.sectionPath).trimToNull
				password := Uri.decodeToken(userInfo.getSafe(1) ?: "", Uri.sectionPath).trimToNull
				
				// don't override existing explicit config - I think .password should override userinfo
				if (username != null && !props.containsKey(userkey))
					props[userkey] = username
				if (username != null && !props.containsKey(passkey))
					props[passkey] = password

				// remove the userinfo from the repo URL
				props[key] = path.replace("${url.userInfo}@", "")
			}
		}
		
		this.file	= propsFile
		this.props	= props
		this.macros	= macros
	}
}

** FpmProps models config from a single 'fpm.props' file. All macros are applied to config on construction.
const class FpmProps {

	** The 'fpm.props' file this instance represents.
	const File		file

	** A list of working directories.
	const File[]	workDirs
	
	** The temp directory.
	const File?		tempDir
	
	** A map of named directory repositories. These repors are essentially just dirs of pods. 
	const Str:File	dirRepos
	
	** A map of named fanr repositories, may be local or remote.
	const Str:Uri	fanrRepos
	
	** A list of libraries used to launch applications
	const Str[]		launchPods

	** Macros, as defined in this file.
	const Str:Str	macros

	** The raw FPM config.
	** Does not include fanr credentials.
	const Str:Str	props

	private new makePrivate(|This|in) { in(this) }
	
	new make(RawProps rawProps, Str:Str allMacros) {
		baseDir		:= rawProps.file.parent
		fpmProps	:= rawProps.props
		
		// do a blanket search / replace on all values 
		fpmProps	 = fpmProps.map |str| {
			allMacros.each |val, key| { str = str.replace("\$${key}", val).replace("\${${key}}", val) }
			return str
		}

		workDirs := fpmProps.containsKey("workDirs")
			? fpmProps["workDirs"].split(File.pathSep.chars.first).exclude { it.isEmpty }.map |dir->File| { toRelDir(dir, baseDir) }.unique
			: File#.emptyList
		
		tempDir := fpmProps.containsKey("tempDir")
			? toRelDir(fpmProps["tempDir"], baseDir)
			: null

		dirRepos := Str:File[:] { ordered=true } 
		fpmProps.keys.findAll { it.startsWith("dirRepo.") }.sort.each |key| {
			path := fpmProps[key]
			if (path == null) return 			// allow config to be removed
			name := key["dirRepo.".size..-1]
			file := toRelDir(path, baseDir)
			dirRepos[name] = file
		}

		fanrRepos := Str:Uri[:] { ordered=true }
		fpmProps.keys.findAll { it.startsWith("fanrRepo.") && !it.endsWith(".username") && !it.endsWith(".password") }.sort.each |key| {
			path := fpmProps[key].trimToNull
			if (path == null) return 			// allow config to be removed
			name := key["fanrRepo.".size..-1]
			url  := Uri(path)
			if (url?.scheme != "http" && url?.scheme != "https")
				url = toRelDir(path, baseDir).uri
			fanrRepos[name] = url
		}

		// as Env is available to the entire FVM, be nice and remove any credentials
		// it's just lip service really, as anyone could re-read the fpm.config files
		// so yeah, don't bother - it's just an display problem
//		allProps := fpmProps.exclude |val, key| { key.endsWith(".username") || key.endsWith(".password") }

		both := dirRepos.keys.intersection(fanrRepos.keys)
		if (both.size > 0)
			throw Err("Repository '" + both.join(", ") + "' is defined as both a dirRepo AND a fanrRepo")

		this.file			= rawProps.file
		this.workDirs		= workDirs
		this.tempDir		= tempDir
		this.dirRepos		= dirRepos
		this.fanrRepos		= fanrRepos
		this.launchPods 	= fpmProps["launchPods"]?.split(',') ?: Str#.emptyList
		this.props			= fpmProps
		this.macros			= rawProps.macros
	}

	Bool hasClearCmd() {
		props["clear.all"] != null || props["configCmd"] == "clearExisting"
	}
	
	** Returns the config value associated with the given key.
	@Operator
	Str? get(Str key) {
		props.get(key)
	}
	
	** Iterates over each key value config pair.
	Void each(|Str val, Str key| fn) {
		props.each(fn)
	}
	
//	** Returns a 'Repository' instance for the named repository. 
//	** 'repoName' may be either a 'dirRepo' or a 'fanrRepo'. 
//	Repository? repository(Str repoName, Str? username := null, Str? password := null) {
//		
//		if (dirRepos.containsKey(repoName))
//			return LocalDirRepository(repoName, dirRepos[repoName])
//		
//		if (fanrRepos.containsKey(repoName)) {
//			if (username == null)
//				username = _rawConfig["fanrRepo.${repoName}.username"]
//			if (password == null)
//				password = _rawConfig["fanrRepo.${repoName}.password"]
//			url := fanrRepos[repoName]
//			if (url.scheme == null   || url.scheme == "file")
//				return LocalFanrRepository(repoName, url.toFile)
//			if (url.scheme == "http" || url.scheme == "https")
//				return RemoteFanrRepository(repoName, url, username, password)
//			throw ArgErr("Unknown scheme '${url.scheme}' in $url")
//		}
//
//		return null
//	}

	** Dumps debug output to a string. The string will look similar to:
	** 
	** pre>
	**          File : C:\Apps\fantom-1.0.70\etc\afFpm\config.props
	**     Work Dirs : C:\Repositories\Fantom
	**                 C:\Apps\fantom-1.0.70
	**      Temp Dir : C:\Repositories\Fantom\temp
	** 
	**     Dir Repos :
	**       workDir = C:\Repositories\Fantom
	** 
	**    Fanr Repos :
	**       default = C:\Repositories\Fantom\repo-default
	**        eggbox = http://eggbox.fantomfactory.org/fanr/
	** <pre
	Str dump() {
		str := ""
		str += "          File : " + dumpList([file])
		str += "     Work Dirs : " + dumpList(workDirs)
		str += "      Temp Dir : " + dumpList([tempDir].exclude { it == null })

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
			usr	:= repoUrl.userInfo == null ? "" : repoUrl.userInfo + "@"
			url	:= repoUrl.toStr.replace(usr, "")
			str += name.justr(max) + " = " + url + "\n"
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
