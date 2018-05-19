
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
	
	** The pod this environment is targeted to.
	const Depend			targetPod

	** A map of dependent pods that have been resolved specifically for the 'targetPod'. 
	const Str:PodFile		resolvedPods
	
	** A list of unsatisfied pods for this targeted environment.
	const Str:UnresolvedPod	unresolvedPods

	@NoDoc
	static new make() {
		FpmEnvDefault()
	}

	@NoDoc
	new makeManual(FpmConfig fpmConfig, File[] f4PodFiles, |This|? in := null) : super.make(Env.cur) {
		in?.call(this)	// let F4 set its own logger

		title := "Fantom Pod Manager ${typeof.pod.version}"
		if (log.isDebug) {
			log.debug("")
			log.debug("${title}")
			log.debug("".padl(title.size, '='))		
			log.debug("")
		}

		this.fpmConfig	= fpmConfig

		resolver := Resolver(fpmConfig.repositories).localOnly
		
		try {
			targetPod	 := findTarget
			podSatisfier := Satisfier(targetPod, resolver) {
				it.log	= this.log
			}
			podSatisfier.satisfyDependencies
			
			this.targetPod		= podSatisfier.targetPod
			this.resolvedPods	= podSatisfier.resolvedPods
			this.unresolvedPods	= podSatisfier.unresolvedPods

		} catch (UnknownPodErr err) {
			// todo auto-download / install the pod dependency!??
			// beware, also thrown by BuildPod on malformed dependency str
			error = err

		} catch (Err err) {
			error = err

		} finally {
			this.unresolvedPods	= this.unresolvedPods	!= null ? this.unresolvedPods	: [:]
			this.resolvedPods	= this.resolvedPods		!= null ? this.resolvedPods		: [:]
			this.targetPod		= this.targetPod		!= null ? this.targetPod		: Depend("??? 0")
		}
		
		loggedLatest := false
		if (targetPod.name == "???")
			if (!loggedLatest) {
				loggedLatest = true
				log.info("FPM: Could not target pod - defaulting to latest pod versions")
				this.resolvedPods = resolver.resolveAll
			}

		if (Env.cur.vars["FPM_ALL_PODS"]?.toBool(false) ?: false)
			if (!loggedLatest) {
				loggedLatest = true
				log.info("FPM: Found env var: FPM_ALL_PODS = true; making all pods available")
				this.resolvedPods = resolver.resolveAll
			}
		
		// ---- dump info to logs ----
		
		// if there's something wrong, then make sure the user sees the dump
		if (error != null || unresolvedPods.size > 0)
			log.info(dump)

		if (unresolvedPods.size > 0) {
			log.warn(Utils.dumpUnresolved(unresolvedPods.vals))
			if (!loggedLatest) {
				loggedLatest = true
				log.warn("Defaulting to latest pod versions")
				this.resolvedPods = resolver.resolveAll
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
	abstract TargetPod findTarget()

	** Dumps the FPM environment to a string. This includes the FPM Config and a list of resolved pods.
	Str dump() {
		Utils.dumpEnv(targetPod, resolvedPods.vals, fpmConfig)
	}
}

@NoDoc
const class TargetPod {
	const Depend	pod
	const Depend[]?	dependencies

	new make(Depend pod, Depend[]? dependencies := null) {
		this.pod			= pod
		this.dependencies	= dependencies
	}
	
	internal static new fromBuildPod(BuildPod buildPod) {
		podName	:= buildPod.podName 
		version	:= buildPod.version 
		depends	:= buildPod.depends 
		return TargetPod(Depend("$podName $version"), depends.map { Depend(it, false) }.exclude { it == null })
	}
	
	Bool resolveDependencies() {
		dependencies == null
	}
	
	PodFile podFile() {
		PodFile(pod.name, pod.version, dependencies, `targetpod:${pod.name}`, StubPodRepository.instance)
	}
}
