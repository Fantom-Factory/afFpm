
** FpmProps models properties from a chain of 'RawProps'.
@NoDoc
const class FpmProps {

	** The RawProps that back this class instance.
	const RawProps	rawProps

	** A list of working directories.
	const Str[]		workDirs
	
	** The temp directory.
	const Str?		tempDir
	
	** A map of named directory repositories. These repors are essentially just dirs of pods. 
	const Str:Str	dirRepos
	
	** A map of named fanr repositories, may be local or remote.
	const Str:Str	fanrRepos
	
	** A list of libraries used to launch applications
	const Str[]		launchPods

	** Macros, as defined in this file.
	const Str:Str	macros

//	** The underlying properties.
//	const Str:Str	props

//	// let's NOT change the pathSep per platform - we need config files to work on ANY OS
//	private static const Str _pathSepStr	:= ";"
//	private static const Int _pathSepInt	:= ';'

//	private new makePrivate(|This|in) { in(this) }

	static new fromProps(Str:Str props) {
		FpmProps(RawProps(props))
	}

	static new fromFile(File file) {
		FpmProps(RawProps(file))
	}

	new make(RawProps rawProps) {

		allProps	:= rawProps.allProps
		workDirs	:= allProps["workDirs"]
		tempDir		:= allProps["tempDir"]
		launchPods 	:= allProps["launchPods"]?.split(',')?.exclude { it.isEmpty }?.unique ?: Str#.emptyList
		
		dirRepos := Str:File[:] { ordered=true } 
		allProps.keys.findAll { it.startsWith("dirRepo.") }.sort.each |key| {
			path := allProps[key]
			if (path.size > 0)	// allow config to be removed
				dirRepos[key["dirRepo.".size..-1]] = allProps[key]
		}

		fanrRepos := Str:Uri[:] { ordered=true }
		allProps.keys.findAll { it.startsWith("fanrRepo.") && !it.endsWith(".username") && !it.endsWith(".password") }.sort.each |key| {
			path := allProps[key]
			if (path.size > 0)	// allow config to be removed
				dirRepos[key["fanrRepo.".size..-1]] = allProps[key]
		}

		both := dirRepos.keys.intersection(fanrRepos.keys)
		if (both.size > 0)
			throw Err("Repository '" + both.join(", ") + "' is defined as both a dirRepo AND a fanrRepo")

		macros	:= Str:Str[:] { it.ordered = true }
		allProps.keys.each |key| {
			if (key.startsWith("macro."))
				macros[key["macro.".size..-1]] = allProps[key]
		}

		this.rawProps		= rawProps
		this.workDirs		= workDirs
		this.tempDir		= tempDir
		this.dirRepos		= dirRepos
		this.fanrRepos		= fanrRepos
		this.macros			= macros
		this.launchPods 	= launchPods
	}

//	** Dumps debug output to a string. The string will look similar to:
//	** 
//	** pre>
//	**          File : C:\Apps\fantom-1.0.70\etc\afFpm\config.props
//	**     Work Dirs : C:\Repositories\Fantom
//	**                 C:\Apps\fantom-1.0.70
//	**      Temp Dir : C:\Repositories\Fantom\temp
//	** 
//	**     Dir Repos :
//	**       workDir = C:\Repositories\Fantom
//	** 
//	**    Fanr Repos :
//	**       default = C:\Repositories\Fantom\repo-default
//	**        eggbox = http://eggbox.fantomfactory.org/fanr/
//	** <pre
//	Str dump() {
//		str := ""
//		str += "         Files : " + dumpList(files)
//		str += "     Work Dirs : " + dumpList(workDirs)
//		str += "      Temp Dir : " + dumpList([tempDir].exclude { it == null })
//
//		str += "\n"
//		str += "     Dir Repos : " + (dirRepos.isEmpty ? "(none)" : "") + "\n"
//		max := dirRepos.keys.reduce(14) |Int size, name| { size.max(name.size) } as Int
//		dirRepos.each |file, name| {
//			exists := file.exists ? "" : " (does not exist)"
//			str += name.justr(max) + " = ${file.osPath}${exists}\n"
//		}
//
//		str += "\n"
//		str += "    Fanr Repos : " + (fanrRepos.isEmpty ? "(none)" : "") + "\n"
//		max = fanrRepos.keys.reduce(14) |Int size, name| { size.max(name.size) } as Int
//		fanrRepos.each |repoUrl, name| {
//			usr	:= repoUrl.userInfo == null ? "" : repoUrl.userInfo + "@"
//			url	:= repoUrl.toStr.replace(usr, "")
//			str += name.justr(max) + " = " + url + "\n"
//		}
//
//		str += "\n"
//		str += "        Macros : " + (macros.isEmpty ? "(none)" : "") + "\n"
//		max = macros.keys.reduce(14) |Int size, name| { size.max(name.size) } as Int
//		macros.each |value, name| {
//			str += name.justr(max) + " = ${value}\n"
//		}
//
//		return str
//	}
//
//	private Str dumpList(File[] files) {
//		if (files.isEmpty)
//			return "(none)\n"
//
//		ext := files.first.exists ? "" : " (does not exist)"
//		str := "${files.first.osPath}${ext}\n"
//		if (files.size > 1)
//			files[1..-1].each {
//				exists := it.exists ? "" : " (does not exist)"
//				str += "".justr(14) + "   ${it.osPath}${exists}\n"
//			}
//		return str
//	}
//	
//	private static File toRelDir(Str dirPath, File baseDir) {
//		FileUtils.toAbsDir(dirPath, baseDir)
//	}
}
