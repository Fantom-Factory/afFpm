
** Originally, this existed so I could create an F4 version.
** But I guess this *could* now be merged in to FpmEnv.
** Hmm... but I like the split / separation of concerns!
internal const class FpmEnvDefault : FpmEnv {

	static new make() {
		try {
			if (Env.cur.vars["FPM_DEBUG"]?.lower?.toBool(false) == true)
				FpmEnv#.pod.log.level = LogLevel.debug

			return makeManual(FpmConfig())
			
		} catch (Err e) {
			// this is really just belts and braces for FPM development as
			// otherwise we don't get a useful stack trace
			Env.cur.err.print(e.traceToStr)
			throw e
		}
	}
	
	private new makeManual(FpmConfig fpmConfig, |This|? in := null) : super.makeManual(fpmConfig, in) { }

	override TargetPod? findTarget() {
		fanArgs	:= Env.cur.args
		fpmArgs	:= Utils.splitQuotedStr(Env.cur.vars["FPM_TARGET"])
		cmdArgs	:= fpmArgs ?: fanArgs
		
		// a fail safe / get out jail card for pin pointing the targeted environment 
		idx := cmdArgs.index("-fpmTarget")
		if (idx != null) {
			podDepend := findPodDepend(cmdArgs.getSafe(idx + 1))
			if (podDepend != null)
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
			
			// scripts don't have pod targets, so default to using the latest pods
			if (cmdArgs.first.endsWith(".fan"))
				return null
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

		if (arg.contains("::"))
			arg = arg[0..<arg.index("::")]

		arg = arg.replace("@", " ")
		
		if (!arg.contains(" "))
			arg += " 0+"

		if (arg.all { isAlphaNum || equals(' ') || equals('.') || equals('-') || equals('+') })
			return Depend(arg, false)
		
		return null
	}
}