
** Provides a targeted environment for a specific pod. 
** 
** The WorkDirs and HomeDir are always queried if a pod is not found in a local repository.
abstract const class FpmEnv : Env {
	@NoDoc	// so F4 can set it's own
	const Log 				log 	:= FpmEnv#.pod.log

	** The error, if any, encountered when resolving pods for the target environment.
	const Err?				error
	
	** The config used for this environment.
	const FpmConfig			fpmConfig
	
	** The name of the pod this environment is targeted to.
	const Str				targetPod

	** A map of dependent pods that have been resolved specifically for the 'targetPod'. 
	const Str:PodFile		resolvedPods
	
	** A list of unsatisfied pods for this targeted environment.
	const UnresolvedPod[]	unresolvedPods

	@NoDoc
	static new make() {
		FpmEnvDefault()
	}

	@NoDoc
	new makeManual(FpmConfig fpmConfig, File[] f4PodFiles, |This|? in := null) : super.make(Env.cur) {
		in?.call(this)	// can't do field null comparison without an it-block ctor

		title := "Fantom Pod Manager ${typeof.pod.version}"
		if (log.isDebug) {
			log.debug("")
			log.debug("${title}")
			log.debug("".padl(title.size, '='))		
			log.debug("")
		}

		this.fpmConfig	= fpmConfig

		repositories := Repositories(fpmConfig.repositories).localOnly
		
		try {
			podSatisfier	:= Satisfier {
				it.log			= this.log
				it.repositories	= repositories
			}
			findTarget(podSatisfier)
			podSatisfier.satisfyDependencies
			
			targetPod		= podSatisfier.targetPod ?: "???"
			resolvedPods	= podSatisfier.resolvedPods
			unresolvedPods	= podSatisfier.unresolvedPods
			if (targetPod.endsWith(" 0"))
				targetPod += "+"

		} catch (UnknownPodErr err) {
			// todo auto-download / install the pod dependency!??
			// beware, also thrown by BuildPod on malformed dependency str
			error = err

		} catch (Err err) {
			error = err

		} finally {
			this.unresolvedPods	= this.unresolvedPods	!= null ? this.unresolvedPods	: [,]
			this.resolvedPods	= this.resolvedPods		!= null ? this.resolvedPods		: [:]
			this.targetPod		= this.targetPod		!= null ? this.targetPod		: "???"
		}
		
		loggedLatest := false
		if (targetPod == "???")
			if (!loggedLatest) {
				loggedLatest = true
				echo("FPM: Could not target pod - defaulting to latest pod versions")
				this.resolvedPods = repositories.resolveAll
			}

		if (Env.cur.vars["FPM_ALL_PODS"]?.toBool(false) ?: false)
			if (!loggedLatest) {
				loggedLatest = true
				echo("FPM: Found env var: FPM_ALL_PODS = true; making all pods available")
				this.resolvedPods = repositories.resolveAll
			}
		
		// ---- dump info to logs ----
		
		if (!targetPod.startsWith("afFpm"))
			// if there's something wrong, then make sure the user sees the dump
			if (error != null || unresolvedPods.size > 0)
				log.info(dump)
			 else
				if (log.isDebug)
					log.debug(dump)

		if (unresolvedPods.size > 0) {
			log.warn(Utils.dumpUnresolved(unresolvedPods))
			if (!loggedLatest) {
				loggedLatest = true
				log.warn("Defaulting to latest pod versions")
				this.resolvedPods = repositories.resolveAll
			}
		}

		if (error != null) {
			log.err  (error.toStr)
			log.debug(error.traceToStr)
		}
	}

	@NoDoc
	override File workDir() {
		fpmConfig.workDirs.first
	}

	@NoDoc
	override File tempDir() {
		fpmConfig.tempDir
	}
	
	** Return the list of pod names for all the pods currently installed in this environment.
	override Str[] findAllPodNames() {
		resolvedPods.keys 
	}

	** Resolve the pod file for the given pod name.
	override File? findPodFile(Str podName) {
		resolvedPods[podName]?.file
	}

	** Find all the files in the environment which match a relative path such as 'etc/foo/config.props'. 
	override File[] findAllFiles(Uri uri) {
		if (uri.isPathAbs) throw ArgErr("Uri must be rel: $uri")
		return fpmConfig.workDirs.map { it + uri }.exclude |File f->Bool| { f.exists.not }
	}

	** Find a file in the environment using a relative path such as 'etc/foo/config.props'. 
	override File? findFile(Uri uri, Bool checked := true) {
		if (uri.isPathAbs) throw ArgErr("Uri must be rel: $uri")
		return fpmConfig.workDirs.eachWhile |dir| {
			f := dir.plus(uri, false)
			return f.exists ? f : null
		} ?: (checked ? throw UnresolvedErr(uri.toStr) : null)
	}

	@NoDoc
	internal abstract Void findTarget(Satisfier satisfier)

	** Dumps the FPM environment to a string. This includes the FPM Config and a list of resolved pods.
	Str dump() {
		str	:= "\n\n"
		str += "FPM Environment:\n"
		str += "\n"
		str += "    Target Pod : ${targetPod}\n"
		str += fpmConfig.dump
		str += "\n"
		str += "Resolved ${resolvedPods.size} pod" + (resolvedPods.size == 1 ? "" : "s") + (resolvedPods.size == 0 ? "" : ":") + "\n"
		
		maxNom := resolvedPods.reduce(0) |Int size, pod| { size.max(pod.name.size) } as Int
		maxVer := resolvedPods.reduce(0) |Int size, pod| { size.max(pod.version.toStr.size) }
		resolvedPods.keys.sort.each |key| {
			podFile := resolvedPods[key]
			str += podFile.name.justr(maxNom + 2) + " " + podFile.version.toStr.justl(maxVer) + " - " + podFile.file.osPath + "\n"
		}
		str += "\n"
		
		// unsatisfied constraints and errors should be logged separately after this dump 

		return str
	}
}
