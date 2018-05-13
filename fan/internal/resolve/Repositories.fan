
internal class Repositories {
	private Repository[]		repositories
	private Depend:PodFile[]	cash		:= Depend:PodFile[][:]

	new make(Repository[] repositories) {
		this.repositories = repositories
	}
	
	This localOnly() {
		repositories = repositories.findAll { it.isLocal }
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

	PodFile[] resolve(Depend dependency) {
		cash.getOrAdd(dependency) |->PodFile[]| {
			
			// first lets check if this dependency 'fits' into any existing
			// we don't want to contact remote fanr repos if we don't have to
			existing := cash.find |vers, dep->Bool| { Utils.dependFits(dependency, dep) }
			
			if (existing != null) {
				// only return what we need
				return existing.findAll { dependency.match(it.version) }
			}
			
			// naa, lets do the full resolve hog
			allVersions := (PodFile[]) repositories.map { it.resolve(dependency) }.flatten
			
			// we could just do 'allVersions.unique()' but we want to make sure local podVersions trump remote ones 
			versions := allVersions.findAll { it.repository.isLocal }.unique
			allVersions.each {
				if (!it.repository.isLocal && !versions.contains(it)) 
					versions.add(it)
			}
			return versions
		}
	}
}
