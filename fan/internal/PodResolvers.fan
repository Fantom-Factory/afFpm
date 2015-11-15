
class PodResolvers {
	PodResolver[] 	resolvers
	Depend:PodMeta	depends		:= Depend:PodMeta[:]
	
	new make(FpmConfig config, FileCache fileCache) {
		resolvers = PodResolver[
			PodResolverFanr(config.repoDir, fileCache)
		].addAll(
			config.paths.map |path->PodResolver| { PodResolverPath(path, fileCache) }
		)
	}
	
	PodMeta? resolve(Depend dependency) {
		depends.getOrAdd(dependency) {
			resolvers.eachWhile { it.resolve(dependency) }
		}
	}
}

mixin PodResolver {
	abstract PodMeta? resolve(Depend dependency)
}

class PodResolverFanr : PodResolver {
	private static const Regex		podRegex		:= "(.+)-(.+)\\.pod".toRegex

	FileCache	fileCache
	File 		repoDir

	new make(File repoDir, FileCache fileCache) {
		this.repoDir	= repoDir
		this.fileCache	= fileCache
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
			
			return fileCache.get(file)

		}.exclude { it == null }
		
		podMeta := files.sort |p1, p2| { p1.version <=> p2.version }.last
		return podMeta
	}
}

class PodResolverPath : PodResolver {
	FileCache	fileCache
	File 		pathDir

	new make(File pathDir, FileCache fileCache) {
		this.pathDir	= pathDir
		this.fileCache	= fileCache
	}

	override PodMeta? resolve(Depend dependency) {
		file := pathDir.plus(`lib/fan/${dependency.name}.pod`)
		if (file.exists.not)
			return null
		
		podMeta := (PodMeta?) fileCache.get(file)

		if (!dependency.match(podMeta.version))
			podMeta = null
		
		return podMeta
	}
}