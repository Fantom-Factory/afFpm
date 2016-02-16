
internal const class FpmEnvDefault : FpmEnv {

	static new make() {
		fpmConfig	:= FpmConfig()

		// add F4 pod locations
		f4PodPaths	:= Env.cur.vars["FAN_ENV_PODS"]?.trimToNull?.split(File.pathSep.chars.first, true) ?: Str#.emptyList
		f4PodFiles	:= f4PodPaths.map { toFile(it) }
		fpmEnv 		:= makeManual(fpmConfig, f4PodFiles)

		return fpmEnv
	}
	
	private new makeManual(FpmConfig fpmConfig, File[] podFiles, |This|? in := null) : super.makeManual(fpmConfig, podFiles, in) { }

	override Void findTarget(PodDependencies podDepends) {
		fanArgs	:= Env.cur.args
		fpmArgs	:= splitQuotedStr(Env.cur.vars["FPM_TARGET"])
		cmdArgs	:= fpmArgs ?: fanArgs
		
		// a fail safe / get out jail card for pin pointing the targeted environment 
		idx := cmdArgs.index("-fpmPod")
		if (idx != null) {
			podDepend := findPodDepend(cmdArgs.getSafe(idx + 1))
			podDepends.setRunTarget(podDepend)
			return
		}

		// FPM_TARGET - use it if we got it
		if (fpmArgs != null) {
			buildPod := getBuildPod(cmdArgs.first)		
			if (buildPod != null) {
				podDepends.setBuildTargetFromBuildPod(buildPod, true)
				return
			}

			podDepend := findPodDepend(cmdArgs.first)
			if (podDepend != null) {
				podDepends.setRunTarget(podDepend)
				return
			}
		}

		// this is only good for basic 'C:\>fan afEggbox' type cmds
		// any fant or script / build cmds still need to use alternative means
		mainMethod := null as Method 
		if (Pod.find("sys").version >= Version("1.0.68")) {
			mainMethod = Env.cur.mainMethod 
			if (mainMethod != null) {
	
				// make a HUGE assumption here that the build script is the one in the current directory
				// TODO ask Brian how to get the running script file location
				if (mainMethod.qname == "build::BuildPod.main") {
					buildPod := getBuildPod("build.fan")		
					if (buildPod != null) {
						podDepends.setBuildTargetFromBuildPod(buildPod, true)
						return
					}
				}
				
				podDepend := Depend("${mainMethod.parent.pod.name} 0+")
				podDepends.setRunTarget(podDepend)
				return
			}
		}

		log.warn("Could not parse pod from: mainMethod: ${mainMethod?.qname} or args: ${cmdArgs.first} / $Env.cur.args")
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

	** Returns build::BuildPod but we can't be arsed with a dependency on build
	static Obj? getBuildPod(Str? filePath) {
		try {
			if (filePath == null)
				return null
			file := filePath.startsWith("file:") ? File(filePath.toUri, false) : File.os(filePath)
			if (file.isDir || file.exists.not || file.ext != "fan")
				return null
			
			// use Plastic because the default pod name when running a script (e.g. 'build_0') is already taken == Err
			buildPodType := Type.find("build::BuildPod")
			obj := PlasticCompiler().compileCode(file.readAllStr).types.find { it.fits(buildPodType) }?.make
			
			// if it's not a BuildPod instance, return null - e.g. it may just be a BuildScript instance!
			return obj
		} catch
			return null
	}
	
	static Str[]? splitQuotedStr(Str? str) {
		if (str?.trimToNull == null)	return null
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