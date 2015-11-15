
class PodResolvers {
	PodResolver[] resolvers

	new make(FpmConfig config, PodCache podCache) {
		resolvers = [
			PodResolverFanr(config.repoDir, podCache)
		].addAll(
			config.paths.map { PodResolverPath(it, podCache) }
		)
	}
	
	PodMeta? resolve(Depend dependency) {
		resolvers.eachWhile { it.resolve(dependency) }
	}
}

mixin PodResolver {
	abstract PodMeta? resolve(Depend dependency)
}

class PodResolverFanr : PodResolver {
	private static const Regex		podRegex		:= "(.+)-(.+)\\.pod".toRegex

	PodCache	podCache
	File 		repoDir

	new make(File repoDir, PodCache podCache) {
		this.repoDir	= repoDir
		this.podCache	= podCache
	}

	override PodMeta? resolve(Depend dependency) {
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
		return podMeta
	}
}

class PodResolverPath : PodResolver {
	PodCache	podCache
	File 		pathDir

	new make(File pathDir, PodCache podCache) {
		this.pathDir	= pathDir
		this.podCache	= podCache
	}

	override PodMeta? resolve(Depend dependency) {
		file := pathDir.plus(`lib/fan/${dependency.name}.pod`)
		if (file.exists.not)
			return null
		
		podMeta := (PodMeta?) podCache.get(file)

		if (!dependency.match(podMeta.version))
			podMeta = null
		
		return podMeta
	}
}