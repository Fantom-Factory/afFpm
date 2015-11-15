internal class PodDependencies {

	PodResolvers	podResolvers
	PodCache		podCache		:= PodCache()
	Str:PodMeta		podFiles		:= Str:PodMeta[:]

	new make(FpmConfig config) {
		this.podResolvers	= PodResolvers(config, podCache)
	}
	
	This addPod(Depend dependency) {
		podMeta := resolve(dependency)?.with {
			it.versionFixed = true
		}
		if (podMeta == null)
			throw Err("Could not resolve '${dependency}'")
		podFiles[dependency.name] = podMeta
		return this
	}
	
	This calculateDependencies() {
		
		return this
	}
	
	PodMeta? resolve(Depend dependency) {		
		podResolvers.resolve(dependency)
	}
	
	Str:PodFile getPodFiles() {
		podFiles.exclude { it.inRepo.not }.map { it.toPodFile }
	}
}
