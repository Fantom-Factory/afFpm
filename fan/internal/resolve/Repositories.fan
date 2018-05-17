
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
	
	Str:PodFile resolveAll() {
		pods := Str:PodFile[:]
		repositories.map { it.resolveAll }.flatten.each |PodFile pod| {
			if (!pods.containsKey(pod.name) || pods[pod.name].version <= pod.version)
				pods[pod.name] = pod
		}
		return pods
	}

	** Called by Satisfier
	PodFile[] resolve(Depend dependency, Str:Obj? options) {
		isLocal		// this saves ~40 ms and ~700 invocations on cwApp
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
		repositories.map { it.resolve(dependency, options) }.flatten
	}
}
