
** FpmProps models properties from a chain of 'RawProps'.
@NoDoc
const class FpmProps {

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

	// let's NOT change the pathSep per platform - we need config files to work on ANY OS
	private static const Int _pathSepInt	:= ';'

	new make(Str:Str allProps) {
		workDirs	:= allProps["workDirs"]?.split(_pathSepInt)?.exclude { it.isEmpty }?.unique ?: Str#.emptyList
		tempDir		:= allProps["tempDir"]
		launchPods 	:= allProps["launchPods"]?.split(',')?.exclude { it.isEmpty }?.unique ?: Str#.emptyList
		
		dirRepos := Str:Str[:] { ordered=true } 
		allProps.keys.findAll { it.startsWith("dirRepo.") }.sort.each |key| {
			path := allProps[key]
			if (path.size > 0)	// allow config to be removed
				dirRepos[key["dirRepo.".size..-1]] = allProps[key]
		}

		fanrRepos := Str:Str[:] { ordered=true }
		allProps.keys.findAll { it.startsWith("fanrRepo.") && !it.endsWith(".username") && !it.endsWith(".password") }.sort.each |key| {
			path := allProps[key]
			if (path.size > 0)	// allow config to be removed
				fanrRepos[key["fanrRepo.".size..-1]] = allProps[key]
		}

		both := dirRepos.keys.intersection(fanrRepos.keys)
		if (both.size > 0)
			throw Err("Repository '" + both.join(", ") + "' is defined as both a dirRepo AND a fanrRepo")

		this.workDirs		= workDirs
		this.tempDir		= tempDir
		this.dirRepos		= dirRepos
		this.fanrRepos		= fanrRepos
		this.launchPods 	= launchPods
	}
}
