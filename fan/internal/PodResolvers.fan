
internal class PodResolvers {
	PodResolver[] 		resolvers
	Depend:PodVersion[]	depends		:= Depend:PodVersion[][:]
	
	new make(FpmConfig config, File[] podFiles, FileCache fileCache) {
		// order matters
		resolvers =	PodResolver[,]
			.addAll(
				podFiles.map { PodResolverPod(it, fileCache) }
			).addAll(
				config.repoDirs.vals.map { PodResolverFanr(it, fileCache) }
			).addAll(
				config.podDirs.map { PodResolverPath(it, fileCache) }
			).addAll(
				config.workDirs.map { PodResolverPath(it + `lib/fan/`, fileCache) }
			)
	}
	
	PodVersion[] resolve(Depend dependency) {
		depends.getOrAdd(dependency) {
			resolvers.map { it.resolve(dependency) }.flatten.unique
		}
	}
}

internal mixin PodResolver {
	abstract PodVersion[] resolve(Depend dependency)
}

internal class PodResolverFanr : PodResolver {
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

internal class PodResolverPath : PodResolver {
	FileCache	fileCache
	File 		pathDir

	new make(File pathDir, FileCache fileCache) {
		this.pathDir	= pathDir
		this.fileCache	= fileCache
	}

	override PodVersion[] resolve(Depend dependency) {
		file 		:= pathDir.plus(`${dependency.name}.pod`)	
		podVersion	:= fileCache.get(file)

		if (podVersion != null)
			if (!dependency.match(podVersion.version))
				podVersion = null
		
		return podVersion == null ? PodVersion#.emptyList : [podVersion]
	}
}

internal class PodResolverPod : PodResolver {
	FileCache	fileCache
	File		podFile

	new make(File podFile, FileCache fileCache) {
		this.podFile	= podFile
		this.fileCache	= fileCache
	}

	override PodVersion[] resolve(Depend dependency) {
		podVersion	:= fileCache.get(podFile)

		if (podVersion != null)
			if (!dependency.match(podVersion.version))
				podVersion = null
		
		return podVersion == null ? PodVersion#.emptyList : [podVersion]
	}
}