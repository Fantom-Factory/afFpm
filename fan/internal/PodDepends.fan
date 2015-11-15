internal class PodDependencies {
	private static const Regex		podRegex		:= "(.+)-(.+)\\.pod".toRegex

	File 		repoDir
	PodCache	podCache	:= PodCache()
	Str:PodMeta	podFiles	:= Str:PodMeta[:]

	new make(File repoDir) {
		this.repoDir = repoDir
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
//		if (podFiles.containsKey(dependency.name))
//			return podFiles[]
		
		podDir := repoDir.plus(dependency.name.toUri.plusSlash, true)
		files  := (PodMeta[]) podDir.listFiles(podRegex).map |file->PodMeta?| {
			matcher := podRegex.matcher(file.name)
			if (!matcher.find)
				return null

			if (matcher.group(1) != dependency.name)
				return null
			
			version := Version(matcher.group(2), false)
			if (version == null)
				return null

			if (!dependency.match(version))
				return null
			
			return podCache.get(file) {
				it.inRepo = true
			}

		}.exclude { it == null }
		
		podMeta := files.sort |p1, p2| { p1.version <=> p2.version }.last
		
		if (podMeta == null) {
			// TODO: explicitly check metas and home dir
			file := Env.cur.findPodFile(dependency.name)
			podMeta = podCache.get(file)

			if (!dependency.match(podMeta.version))
				podMeta = null
		}
		
		return podMeta
	}
	
	Str:PodFile getPodFiles() {
		podFiles.exclude { it.inRepo.not }.map { it.toPodFile }
	}
}
