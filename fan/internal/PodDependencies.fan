internal class PodDependencies {

	PodResolvers	podResolvers
	FileCache		fileCache		:= FileCache()
	PodMeta[]		podMetas		:= PodMeta[,]

	Str:PodPicks	podPicks		:= Str:PodPicks[:]
	
	new make(FpmConfig config) {
		this.podResolvers	= PodResolvers(config, fileCache)
	}
	
	This addPod(Depend dependency) {
		podMeta := resolve(dependency)?.with {
			it.versionFixed = true
		}
		if (podMeta == null)
			throw Err("Could not resolve '${dependency}'")
		podMetas.add(podMeta)
		return this
	}
	
	This satisfyDependencies() {
		
		return this
	}
	
	PodMeta? resolve(Depend dependency) {		
		podResolvers.resolve(dependency)
	}

	
	
	
	Str:PodFile getPodFiles() {
//		podFiles.exclude { it.inRepo.not }.map { it.toPodFile }
//		podFiles.map { it.toPodFile }
		[:]
	}
}


class PodPicks {
	const 	Str			name
	const 	Version		version
	const 	File		file
	const	Depend[]	depends
	
			Bool		inRepo
			Bool		versionFixed
	
	new make(|This|in) { in(this) }
	
	
}