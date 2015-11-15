
class PodResolvers {
	PodResolver[] 	resolvers
	Depend:PodVersion[]	depends		:= Depend:PodVersion[][:]
	
	new make(FpmConfig config, FileCache fileCache) {
		resolvers = PodResolver[
			PodResolverFanr(config.repoDir, fileCache)
		].addAll(
			config.paths.map |path->PodResolver| { PodResolverPath(path, fileCache) }
		)
	}
	
	PodVersion[] resolve(Depend dependency) {
		depends.getOrAdd(dependency) {
			resolvers.map { it.resolve(dependency) }.flatten
		}
	}
}

mixin PodResolver {
	abstract PodVersion[] resolve(Depend dependency)
}

class PodResolverFanr : PodResolver {
	private static const Regex		podRegex		:= "(.+)-(.+)\\.pod".toRegex

	FileCache	fileCache
	File 		repoDir

	new make(File repoDir, FileCache fileCache) {
		this.repoDir	= repoDir
		this.fileCache	= fileCache
	}

	override PodVersion[] resolve(Depend dependency) {
		podDir := repoDir.plus(dependency.name.toUri.plusSlash, true)
		return podDir.listFiles(podRegex).map |file->PodVersion?| {
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
	}
}

class PodResolverPath : PodResolver {
	FileCache	fileCache
	File 		pathDir

	new make(File pathDir, FileCache fileCache) {
		this.pathDir	= pathDir
		this.fileCache	= fileCache
	}

	override PodVersion[] resolve(Depend dependency) {
		file 		:= pathDir.plus(`lib/fan/${dependency.name}.pod`)	
		podVersion	:= fileCache.get(file)

		if (podVersion != null)
			if (!dependency.match(podVersion.version))
				podVersion = null
		
		return podVersion == null ? PodVersion#.emptyList : [podVersion]
	}
}