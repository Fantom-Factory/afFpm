
internal class FpmUtils {
	
	static Depend? toDepend(Str str, Bool checked := true) {
		dep := str.replace("/", " ").replace("@", " ")
		if (!dep.contains(" "))
			dep += " 0+"
		return Depend(dep, checked)
	}
	
	static Bool dependFits(Depend dep1, Depend dep2) {
		if (dep1.name != dep2.name)
			return false
		
		ran1 := versionToRangeList(dep1)
		ran2 := versionToRangeList(dep2)

		return ran1.all |ver1| {
			ran2.any |ver2, y| {
				(0..3).toList.eachWhile |Int i->Bool?| {
					contained := ver1[i].start >= ver2[i].start && ver1[i].end <= ver2[i].end
					if (!contained)
						return false
					return (ver1[i].end == ver2[i].end) || dep2.isPlus(y) ? null : true
				} ?: true
			}
		}
	}
	
	private static Range[][] versionToRangeList(Depend dep) {
		(0..<dep.size).toList.map |i->Range[]| {
			if (!dep.isPlus(i) && !dep.isRange(i)) {
				ver := dep.version(i)
				min := Int?[ver.major, ver.minor, ver.build, ver.patch].map { it ?: 0 }
				max := Int?[ver.major, ver.minor, ver.build, ver.patch].map { it ?: Int.maxVal }
				return (0..<4).toList.map |j->Range| { min[j]..max[j] }				
			}
			
			if (dep.isPlus(i)) {
				ver := dep.version(i)
				min := Int?[ver.major, ver.minor, ver.build, ver.patch].map { it ?: 0 }
				return (0..<4).toList.map |j->Range| { min[j]..Int.maxVal }				
			}
			
			if (dep.isRange(i)) {
				ver := dep.version(i)
				end := dep.endVersion(i)
				min := Int?[ver.major, ver.minor, ver.build, ver.patch].map { it ?: 0 }
				max := Int?[end.major, end.minor, end.build, end.patch].map { it ?: Int.maxVal }
				return (0..<4).toList.map |j->Range| { min[j]..max[j] }				
			}
			
			throw Err("WTF is: ${dep.version(i)}")
		}
	}

	** Dumps the output similar to the following:
	** 
	** pre>
	** Could not satisfy the following constraints:
	** 
	**     afPlastic (1.2, 1.3)
	**         afIoc/2.1 ------> afPlastic 1.2
	**         afBedSheet/1.5 -> afPlastic 1.4
	** 	
	**     afEfan (1.5, 1.2, 2.3)
	**         afIoc/2.1 ------> afEfan 1.2
	**         afBedSheet/1.5 -> afEfan 1.4
	** <pre
	static Str dumpUnresolved(UnresolvedPod[] unresolvedPods) {
		if (unresolvedPods.isEmpty) return ""

		output	:= "Could not satisfy the following constraints:\n"
		unresolvedPods.each |unresolvedPod| {
			output	+= unresolvedPod.dump
		}
		return output
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
	
	static TargetPod? findTarget(Env env) {
		envArgs	:= env.args
		envVars := env.vars
		envMain := env.mainMethod
		
		// todo allow multiple target pods!? e.g. xfant AND the test pod?
		// naa - we have "extraPods" now
		
		// a fail safe / get out jail card for pin pointing the targeted environment 
		idx := envArgs.index("-fpmTarget")
		if (idx != null) {
			podDepend := findPodDepend(envArgs.getSafe(idx + 1))
			if (podDepend != null)
				return TargetPod(podDepend)
		}

		// FPM_TARGET - use it if we got it
		fpmArgs	:= FpmUtils.splitQuotedStr(envVars["FPM_TARGET"])
		if (fpmArgs != null) {
			buildPod := BuildPod(fpmArgs.first)
			if (buildPod != null && buildPod.errMsg == null)
				return TargetPod(buildPod)

			podDepend := findPodDepend(fpmArgs.first)
			if (podDepend != null)
				return TargetPod(podDepend)
			
			// scripts don't have pod targets, so default to using the latest pods
			if (fpmArgs.first.endsWith(".fan"))
				return null
		}

		// this is only good for basic 'C:\>fan afEggbox' type cmds
		// any fant or script / build cmds still need to use alternative means
		if (envMain != null) {
			// made a HUGE assumption here that the build script is the one in the current directory
			// not much I can do about it though
			if (envMain.qname == "build::BuildPod.main") {
				buildPod := BuildPod("build.fan")
				if (buildPod.errMsg == null)
					return TargetPod(buildPod)
			}
			
			podDepend := Depend("${envMain.parent.pod.name} 0+")
			return TargetPod(podDepend)
		}

		return null
	}

	private static Depend? findPodDepend(Str? arg) {
		if (arg == null || arg.endsWith(".fan"))
			return null

		if (arg.contains("::"))
			arg = arg[0..<arg.index("::")]

		return toDepend(arg, false)
	}
}
