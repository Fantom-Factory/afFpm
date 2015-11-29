using build

internal const class FpmEnvDefault : FpmEnv {
	private static const Log 	log 	:= FpmEnv#.pod.log

	static new make() {
		fpmConfig	:= FpmConfig()

		// add F4 pod locations
		f4PodPaths	:= Env.cur.vars["F4PODENV_POD_LOCATIONS"]?.trimToNull?.split(File.pathSep.chars.first, true) ?: Str#.emptyList
		f4PodFiles	:= f4PodPaths.map { toFile(it) }
		fpmEnv 		:= makeManual(fpmConfig, f4PodFiles)
		
		log.debug(fpmEnv.debug)

		if (fpmEnv.unsatisfiedConstraints.size > 0) {
			output	:= "Could not satisfy the following constraints:\n"
			maxCon	:= fpmEnv.unsatisfiedConstraints.reduce(0) |Int size, con| { size.max(con.podName.size + con.podVersion.toStr.size + 1) } as Int
			fpmEnv.unsatisfiedConstraints.each {
				output += "${it.podName}@${it.podVersion}".justr(maxCon + 2) + " -> ${it.dependsOn}\n"
			}
			log.warn(output)
		}
		
		if (fpmEnv.error != null) {
			log.err  (fpmEnv.error.toStr)
			log.debug(fpmEnv.error.traceToStr)
		}

		if (fpmEnv.allPodFiles.isEmpty)
			log.warn("Defaulting to PathEnv")
		
		return fpmEnv
	}
	
	new makeManual(FpmConfig fpmConfig, File[] podFiles, |This|? in := null) : super.makeManual(fpmConfig, podFiles, in) { }

	override Void findTarget(PodDependencies podDepends) {
		cmdLineArgs := Env.cur.vars["FPM_CMDLINE_ARGS"]
		if (cmdLineArgs == null)
			log.warn("Env Var 'FPM_CMDLINE_ARGS' not found")

		cmdArgs		:= splitStr(cmdLineArgs)
		buildPod	:= getBuildPod(cmdArgs.first)
		
		if (buildPod != null)
			podDepends.setBuildTarget(buildPod.podName, buildPod.version, buildPod.depends.map { Depend(it, false) }.exclude { it == null } )
		
		if (podDepends.isEmpty) {
			podDepend := findPodDepend(cmdArgs.first)
			
			// given we're making a targeted environment, this is a fail safe / get out jail card 
			if (podDepend == null) {
				idx := cmdArgs.index("-fpmPod")
				if (idx != null)
					podDepend = findPodDepend(cmdArgs.getSafe(idx + 1))
			}
			
			if (podDepend != null)
				podDepends.setRunTarget(podDepend)
		}

		if (podDepends.isEmpty)
			log.warn("Could not parse pod from: ${cmdArgs.first}")
	}

	static Depend? findPodDepend(Str? arg) {
		if (arg == null || arg.endsWith(".fan"))
			return null

		// TODO: check for version e.g. afIoc@3.0
		dependStr := (Str?) null
		if (arg.all { isAlphaNum })
			dependStr = arg

		if (dependStr == null && arg.all { isAlphaNum || equals(':') || equals('.') } && arg.contains("::"))
			dependStr = arg[0..<arg.index("::")]

		// double check valid pod names
		if (dependStr == null || dependStr.all { isAlphaNum }.not)
			return null
		
		dependStr += " 0+"

		return Depend(dependStr, true)
	}

	static BuildPod? getBuildPod(Str? filePath) {
		try {
			if (filePath == null)
				return null
			file := filePath.startsWith("file:") ? File(filePath.toUri, false) : File.os(filePath)
			if (file.isDir || file.exists.not || file.ext != "fan")
				return null
			
			// use Plastic because the default pod name when running a script (e.g. 'build_0') is already taken == Err
			return PlasticCompiler().compileCode(file.readAllStr).types.find { it.fits(BuildPod#) }?.make
		} catch
			return null
	}
	
	static Str[] splitStr(Str? str) {
		if (str?.trimToNull == null)	return Str#.emptyList
		strings	 := Str[,]
		chars	 := Int[,]
		prev	 := (Int?) null
		inQuotes := false
		str.each |c| {
			if (c.isSpace && inQuotes.not) { 
				if (chars.isEmpty.not) {
					strings.add(Str.fromChars(chars))
					chars.clear
				}
			} else if (c == '"') {
				if (inQuotes.not)
					if (chars.isEmpty)
						inQuotes = true
					else
						chars.add(c)
				else {
					inQuotes = false
					strings.add(Str.fromChars(chars))
					chars.clear					
				}
				
			} else
				chars.add(c)

			prev = null
		}

		if (chars.isEmpty.not)
			strings.add(Str.fromChars(chars))

		return strings
	}

	static File toFile(Str filePath) {
		file := filePath.startsWith("file:") ? File(filePath.toUri, false) : File.os(filePath)
		return file.normalize
	}
}