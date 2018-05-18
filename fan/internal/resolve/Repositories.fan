

internal class RepoMan {

	Int		maxPods		:= 5
	Bool	corePods	:= true
	Log		log			:= FpmEnv#.pod.log

	private Repositories repositories
	
	new make(Repository[] repositories) {
		this.repositories = Repositories(repositories)
	}
	
	This localOnly() {
		repositories.localOnly
		return this
	}
	
	This remoteOnly() {
		repositories.remoteOnly
		return this
	}
	
	PodFile[] resolve(Depend depend) {
		repositories.resolve(depend, resolveOptions)
	}
	
	PodFile[] satisfy(Depend depend) {
		satisfier := Satisfier(TargetPod(depend), repositories, resolveOptions) { it.log = this.log }
		satisfier.satisfyDependencies
		return satisfier.resolvedPods.vals
	}
	
	Str:Obj? resolveOptions() {
		Str:Obj?[
			"maxPods"	: maxPods,
			"corePods"	: corePods,
			"log"		: log
		]
	}
}


// TODO rename to Resolver
internal class Repositories {
	private Repository[]		repositories
	private Depend:PodFile[]	cash		:= Depend:PodFile[][:]
	private	Bool 				isLocal

	new make(Repository[] repositories) {
		this.repositories = repositories
	}
	
	This localOnly() {
		repositories = repositories.findAll { it.isLocal }
		isLocal = true
		return this
	}
	
	This remoteOnly() {
		repositories = repositories.findAll { it.isRemote }
		isLocal = false
		return this
	}
	
	internal Str:PodFile resolveAll() {
		pods := Str:PodFile[:]
		repositories.map { it.resolveAll }.flatten.each |PodFile pod| {
			if (!pods.containsKey(pod.name) || pods[pod.name].version <= pod.version)
				pods[pod.name] = pod
		}
		return pods
	}

	** Called by Satisfier
	PodFile[] resolve(Depend dependency, Str:Obj? options) {
		isLocal		// this saves ~40 ms and ~70 vs ~700 invocations on cwApp
			? doResolve(dependency, options)
			: cash.getOrAdd(dependency) |->PodFile[]| {
				
				// first lets check if this dependency 'fits' into any existing
				// we don't want to contact remote fanr repos if we don't have to
				existing := cash.find |vers, dep->Bool| { Utils.dependFits(dependency, dep) }
				
				if (existing != null) {
					// only return what we need
					return existing.findAll { dependency.match(it.version) }
				}
				
				// naa, lets do the full resolve hog
				return doResolve(dependency, options)
			}
	}
	
	private PodFile[] doResolve(Depend dependency, Str:Obj? options) {
		podVers := PodFile[,]
		repositories.each {
			pods := it.resolve(dependency, options)
			pods.each |pod| {
				// don't use contains() or compare the URL, because the same version pod may come from different sources
				// and we only need the one!
				existing := podVers.find { it.fits(pod.depend) }
				if (existing == null)
					podVers.add(pod)
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
}
