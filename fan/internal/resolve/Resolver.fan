
internal class Resolver {
	
			Int					maxPods		:= 5
			Bool				corePods	:= true
			Log					log			:= FpmEnv#.pod.log
	
	private Repository[]		repositories
	private Depend:PodFile[]	cash		:= Depend:PodFile[][:]
	private	Bool 				isLocal

	new make(Repository[] repositories) {
		locals  := repositories.findAll { it.isLocal }
		remotes := repositories.findAll { it.isRemote }
		// make sure remotes are last so we make good use of the minVer option
		this.repositories = locals.addAll(remotes)
	}
	
	This localOnly() {
		repositories = repositories.findAll { it.isLocal }
		isLocal = true
		return this
	}
	
	Str:PodFile resolveAll() {
		pods := Str:PodFile[:]
		repositories.map { it.resolveAll }.flatten.each |PodFile pod| {
			if (!pods.containsKey(pod.name) || pods[pod.name].version <= pod.version)
				pods[pod.name] = pod
		}
		return pods
	}

	PodFile[] satisfyPod(Depend depend) {
		satisfy(TargetPod(depend))
	}
	
	PodFile[] satisfyBuild(BuildPod buildPod) {
		satisfy(TargetPod(buildPod))
	}

	private PodFile[] satisfy(TargetPod target) {
		satisfier := Satisfier(target, this) { it.log = this.log }
		satisfier.satisfyDependencies
		return satisfier.resolvedPods.vals
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
