
@NoDoc	// for F4 FPM 
class Resolver {
			Int					maxPods			:= 5
			Bool				corePods		:= true
			Log					log				:= FpmEnv#.pod.log
	
			// let F4 FPM explicitly set these
			Bool				writeTraceFile	:= false
			Duration			resolveTimeout1	:= 5sec
			Duration			resolveTimeout2	:= 10sec

	private Repository[]		repositories
	private Depend:PodFile[]	cash		:= Depend:PodFile[][:]
	private	Bool 				isLocal
	private PodFile[]			f4PodFiles

	new make(Repository[] repositories) {
		f4PodPaths		:= Env.cur.vars["FAN_ENV_PODS"]?.trimToNull?.split(File.pathSep.chars.first, true) ?: Str#.emptyList
		this.f4PodFiles	= f4PodPaths.map { PodFile(FileUtils.toFile(it)) }
		if (log.isDebug && f4PodFiles.size > 0) {
			log.debug("Supplied FAN_ENV_PODS:")
			f4PodFiles.each { log.debug(" - $it") }
			log.debug("")
		}
		
		// ensure pod files can be resolved
		repositories = repositories.rw.addAll(f4PodFiles.map { it.repository })

		locals  := repositories.findAll { it.isLocal  }.unique	// default may == fanHome may == workDir 
		remotes := repositories.findAll { it.isRemote }.unique
		// make sure remotes are last so we make good use of the minVer option
		this.repositories = locals.addAll(remotes)		
		
		if (Env.cur.vars["FPM_TRACE"]?.lower?.toBool(false) == true)
			writeTraceFile = true
		
		timeout1 := Duration(Env.cur.vars.get("FPM_RESOLVE_TIMEOUT_1", ""), false)
		if (timeout1 != null)
			this.resolveTimeout1 = timeout1
		
		timeout2 := Duration(Env.cur.vars.get("FPM_RESOLVE_TIMEOUT_2", ""), false)
		if (timeout2 != null)
			this.resolveTimeout2 = timeout2
	}
	
	This localOnly() {
		repositories = repositories.findAll { it.isLocal }
		isLocal = true
		return this
	}
	
	Str:PodFile resolveAll(Bool dirReposOnly) {
		pods		 := Str:PodFile[:]
		repositories := dirReposOnly ? repositories.findAll { it.isDirRepo } : repositories
		repositories.map { it.resolveAll }.flatten.each |PodFile pod| {
			if (!pods.containsKey(pod.name) || pods[pod.name].version <= pod.version)
				pods[pod.name] = pod
		}
		return pods
	}

	Satisfied satisfyPod(Depend depend) {
		satisfy(TargetPod(depend))
	}
	
	internal Satisfied satisfyBuild(BuildPod buildPod) {
		satisfy(TargetPod(buildPod))
	}
	
	Satisfied satisfy(TargetPod target) {
		satisfier := Satisfier(target, this) {
			it.log				= this.log
			it.writeTraceFile	= this.writeTraceFile
			it.resolveTimeout1	= this.resolveTimeout1
			it.resolveTimeout2	= this.resolveTimeout2
		}
		satisfier.satisfyDependencies
		
		// ensure F4 pod files trump all other pods
		f4PodFiles.each { satisfier.resolvedPods[it.name] = it }

		return Satisfied {
			it.targetPod		= satisfier.targetPod
			it.resolvedPods 	= satisfier.resolvedPods
			it.unresolvedPods	= satisfier.unresolvedPods
		}
	}
	
	PodFile[] resolve(Depend dependency) {
		isLocal		// this saves ~40 ms and ~70 vs ~700 invocations on cwApp
			? doResolve(dependency)
			: cash.getOrAdd(dependency) |->PodFile[]| {
				
				// first lets check if this dependency 'fits' into any existing
				// we don't want to contact remote fanr repos if we don't have to
				existing := cash.find |vers, dep->Bool| { Utils.dependFits(dependency, dep) }
				
				if (existing != null) {
					// only return what we need
					return existing.findAll { dependency.match(it.version) }
				}
				
				// naa, lets do the full resolve hog
				return doResolve(dependency)
			}
	}
	
	Void cleanUp() {
		repositories.each { it.cleanUp }
	}

	private PodFile[] doResolve(Depend dependency) {
		podVers := PodFile[,]
		minVer  := null as Version
		repositories.each {
			pods := it.resolve(dependency, options.rw.set("minVer", minVer))
			pods.each |pod| {
				// don't use contains() or compare the URL, because the same version pod may come from different sources
				// and we only need the one!
				existing := podVers.find { it.fits(pod.depend) }
				if (existing == null) {
					podVers.add(pod)
					if (minVer == null || pod.version > minVer)
						minVer = pod.version
				}
				else {
					// replace remote pods with local versions
					if (existing.repository.isRemote && pod.repository.isLocal) {
						idx := podVers.index(existing)
						podVers[idx] = pod
					}
				}
			}
		}
		return podVers.sortr
	}
	
	private once Str:Obj? options() {
		Str:Obj?[
			"maxPods"	: maxPods,
			"corePods"	: corePods,
			"log"		: log
		]
	}
}

@NoDoc	// for F4 FPM 
const class Satisfied {
	const Depend			targetPod
	const Str:PodFile		resolvedPods
	const Str:UnresolvedPod	unresolvedPods
	
	new make(|This| f) { f(this) }
}
