
internal const class FpmEnvDefault : FpmEnv {

	static new make() {
		try {
			if (Env.cur.vars["FPM_DEBUG"]?.trimToNull == "true")
				FpmEnv#.pod.log.level = LogLevel.debug

			fpmConfig	:= FpmConfig()
	
			// add F4 pod locations
			f4PodPaths	:= Env.cur.vars["FAN_ENV_PODS"]?.trimToNull?.split(File.pathSep.chars.first, true) ?: Str#.emptyList
			f4PodFiles	:= f4PodPaths.map { toFile(it) }
			fpmEnv 		:= makeManual(fpmConfig, f4PodFiles)
	
			return fpmEnv
			
		} catch (Err e) {
			// this is really just belts and braces for FPM development as
			// otherwise we don't get a useful stack trace
			Env.cur.err.print(e.traceToStr)
			throw e
		}
	}
	
	private new makeManual(FpmConfig fpmConfig, File[] podFiles, |This|? in := null) : super.makeManual(fpmConfig, podFiles, in) { }

	override TargetPod findTarget() {
		fanArgs	:= Env.cur.args
		fpmArgs	:= Utils.splitQuotedStr(Env.cur.vars["FPM_TARGET"])
		cmdArgs	:= fpmArgs ?: fanArgs
		
		// a fail safe / get out jail card for pin pointing the targeted environment 
		idx := cmdArgs.index("-fpmPod")
		if (idx != null) {
			podDepend := findPodDepend(cmdArgs.getSafe(idx + 1))
			return TargetPod(podDepend)
		}

		// FPM_TARGET - use it if we got it
		if (fpmArgs != null) {
			buildPod := BuildPod(cmdArgs.first)		
			if (buildPod != null && buildPod.errMsg == null) {
				return TargetPod(buildPod)
			}

			podDepend := findPodDepend(cmdArgs.first)
			if (podDepend != null) {
				return TargetPod(podDepend)
			}
		}

		// this is only good for basic 'C:\>fan afEggbox' type cmds
		// any fant or script / build cmds still need to use alternative means
		mainMethod := null as Method
		if (Pod.find("sys").version >= Version("1.0.68")) {
			mainMethod = Env.cur.mainMethod 
			if (mainMethod != null) {
	
				// made a HUGE assumption here that the build script is the one in the current directory
				// not much I can do about it though
				if (mainMethod.qname == "build::BuildPod.main") {
					buildPod := BuildPod("build.fan")
					if (buildPod.errMsg == null) {
						return TargetPod(buildPod)
					}
				}
				
				podDepend := Depend("${mainMethod.parent.pod.name} 0+")
				return TargetPod(podDepend)
			}
		}

		throw Err("Could not parse pod from: mainMethod: ${mainMethod?.qname ?: Str.defVal} or args: ${cmdArgs.first ?: Str.defVal} - ${Env.cur.args}")
	}

	static Depend? findPodDepend(Str? arg) {
		if (arg == null || arg.endsWith(".fan"))
			return null

		// FIXME ?? check for version e.g. afIoc@3.0
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

	static File toFile(Str filePath) {
		file := filePath.startsWith("file:") ? File(filePath.toUri, false) : File.os(filePath)
		return file.normalize
	}
}