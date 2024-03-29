using concurrent::Actor

** Provides a targeted environment for a specific pod. 
** 
** The WorkDirs and HomeDir are always queried if a pod is not found in a local repository.
const class FpmEnv : Env {
	@NoDoc	// so F4 can set it's own
	const Log 				log 	:= FpmConfig#.pod.log

	** The error, if any, encountered when resolving pods for the target environment.
	const Err?				error
	
	** The config used for this environment.
	const FpmConfig			fpmConfig
	
	** The pod this environment is targeted to.
	const Depend			targetPod

	** Dependent pods that have been resolved specifically for 'targetPod'. 
	** Either this or 'unresolvedPods' will be empty.
	const Str:PodFile		resolvedPods
	
	** Dependent pods for which FPM could not reach a consensus on which version to use.
	** Either this or 'resolvedPods' will be empty.
	const Str:UnresolvedPod	unresolvedPods

	** Pods used in this environment.
	** This is a combination of pods from directory repositories, overridden by any resolved pods.
	** 
	** If the target could not be resolved, then this defaults to the latest version of all known
	** local pods.
	** 
	** By acknowledging pods from fanHome and workDirs, this environment works in a more expected 
	** manner whereby pods not explicitly referenced can still be discovered at runtime (e.g. icons)
	** and index meta inspected.
	const Str:PodFile		environmentPods

	// TODO add targetPod depends to this std ctor - but beware, it's a backwards breaking change!
	@NoDoc	// ensure we have the standard Env ctor: new make(Env env)
	new make(Env? env := null, |This|? in := null) : super.make(env ?: Env.cur) {
		// this was supposed to be thrown when calling "fan -version", but
		// sys::Err: Method not mapped to java.lang.reflect correctly afFpm::FpmEnv.make
		// is thrown at "MethodFunc.isStatic(Method.java:496)" before make() is called
		try		f := File(`./`)
		catch	throw Err("FpmEnv cannot be used if NOT executing a Fantom pod")

		if (Env.cur.vars["FPM_DEBUG"] == "true")
			log.level = LogLevel.debug

		in?.call(this)	// let F4 & LSP set its own logger and fpmConfig

		if (fpmConfig == null)
			fpmConfig = FpmConfig()

		if (log.isDebug) {
			title := "Fantom Pod Manager (FPM) v${typeof.pod.version}"
			log.debug("")
			log.debug("${title}")
			log.debug("".padl(title.size, '-'))		
			log.debug("")
		}

		resolver := Resolver(fpmConfig.repositories).localOnly { it.log	= this.log }
		
		try {
			targetPod	:= findTarget
			if (targetPod != null) {
				satisfied	:= resolver.satisfy(targetPod, fpmConfig.extraPods)
				resolver.cleanUp
				
				this.targetPod		= satisfied.targetPod
				this.resolvedPods	= satisfied.resolvedPods
				this.unresolvedPods	= satisfied.unresolvedPods
				this.environmentPods= resolver.resolveAll(true).setAll(satisfied.resolvedPods)
			}
			
		} catch (UnknownPodErr err) {
			// todo auto-download / install the pod dependency!??
			// beware, also thrown by BuildPod on malformed dependency str
			error = err

		} catch (Err err) {
			error = err

		} finally {
			this.environmentPods= this.environmentPods	!= null ? this.environmentPods	: [:]
			this.unresolvedPods	= this.unresolvedPods	!= null ? this.unresolvedPods	: [:]
			this.resolvedPods	= this.resolvedPods		!= null ? this.resolvedPods		: [:]
			this.targetPod		= this.targetPod		!= null ? this.targetPod		: Depend("??? 0")
		}
		
		loggedLatest := false
		if (targetPod.name == "???")
			if (!loggedLatest) {
				loggedLatest = true
				if (error != null)
					log.warn("FPM: Pod resolve error - defaulting to latest pod versions")
				else
					log.warn("FPM: Could not find target - defaulting to latest pod versions")
				this.environmentPods = resolver.resolveAll(false).setAll(resolvedPods)
			}

		if (Env.cur.vars["FPM_ALL_PODS"]?.lower?.toBool(false) == true)
			if (!loggedLatest) {
				loggedLatest = true
				log.info("FPM: Found env var: FPM_ALL_PODS = true; making all pods available")
				this.environmentPods = resolver.resolveAll(false).setAll(resolvedPods)
			}
		
		// ---- dump stuff to logs ----

		dumped := false

		// if there's something wrong, then make sure the user sees the dump
		if (error != null || unresolvedPods.size > 0) {
			log.warn(dump)
			dumped = true
		}

		if (!dumped && log.isDebug) {
			log.debug(dump)
			dumped = true
		}

		if (unresolvedPods.size > 0) {
			log.warn(FpmUtils.dumpUnresolved(unresolvedPods.vals))
			if (!loggedLatest) {
				loggedLatest = true
				log.warn("Defaulting to latest pod versions")
				this.environmentPods = resolver.resolveAll(false).setAll(resolvedPods)
			}
		}

		if (error != null) {
			log.err  (error.toStr)
			log.debug(error.traceToStr)
		}		
		
		if (Env.cur.vars["FPM_DUMP"]?.lower?.toBool(false) == true) {
			resolver.resolveAll(false)
			resolver.dumpToOut
			echo("\n\nAll pods:\n")
			this.environmentPods.vals.sort.each {
				echo(" = $it.name $it.version")
			}
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
		environmentPods.keys 
	}

	** Resolve the pod file for the given pod name.
	override File? findPodFile(Str podName) {
		environmentPods[podName]?.file
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
	virtual TargetPod? findTarget() {
		target := Actor.locals["afFpm.target"]

		// allow target to be either Depend or TargetPod
		if (target is Depend)
			target = TargetPod((Depend) target)

		target = target as TargetPod
		
		if (target == null)
			target = FpmUtils.findTarget(this)
		
		return target
	}

	** Dumps the FPM environment to a string. This includes the FPM Config and a list of resolved pods.
	virtual Str dump() {
		dumpEnv(targetPod, resolvedPods.vals, fpmConfig)
	}
	
	@NoDoc	// used by F4 FPM
	static Str dumpEnv(Depend targetPod, PodFile[] resolvedPods, FpmConfig? fpmConfig) {
		str	:= "\n\n"
		str += "FPM (${FpmConfig#.pod.version}) Environment:\n"
		str += "\n"
		str += "    Target Pod : ${targetPod}\n"
		str += fpmConfig?.dump ?: ""
		str += "\n"
		str += "Resolved ${resolvedPods.size} pod" + (resolvedPods.size == 1 ? "" : "s") + (resolvedPods.size == 0 ? "" : ":") + "\n"
		
		maxNom := resolvedPods.reduce(0) |Int size, pod| { size.max(pod.name.size) } as Int
		maxVer := resolvedPods.reduce(0) |Int size, pod| { size.max(pod.version.toStr.size) }
		resolvedPods.sort.each |podFile| {
			str += podFile.name.justr(maxNom + 2) + " " + podFile.version.toStr.justl(maxVer) + " - " + podFile.file.osPath + "\n"
		}
		str += "\n"
		
		// unsatisfied constraints and errors should be logged separately after this dump 

		return str
	}
}

@NoDoc
const class TargetPod {
	const Depend	pod
	const Depend[]?	dependencies	// used for build.fan

	// used by F4's FpmCompileEnv and lspFantom
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
	
	PodFile podFile() {
		PodFile(pod.name, pod.version, dependencies, `targetpod:${pod.name}`, StubPodRepository.instance)
	}
}
