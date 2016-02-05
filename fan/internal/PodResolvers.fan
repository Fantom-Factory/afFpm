using fanr

internal class PodResolvers {
	private FileCache 	fileCache
	private File[]		podFiles
	FpmConfig			fpmConfig
	PodResolver[] 		resolvers
	Depend:PodVersion[]	depends		:= Depend:PodVersion[][:]
	
	new make(FpmConfig fpmConfig, File[] podFiles, FileCache fileCache) {
		// order matters
		this.resolvers = PodResolver[,]
			.addAll(
				podFiles.map { PodResolverPod(it, fileCache) }
			).addAll(
				fpmConfig.podDirs.map { PodResolverPath(it, fileCache) }
			).addAll(
				fpmConfig.fileRepos.vals.map { PodResolverFanrLocal(it, fileCache) }
			).addAll(
				fpmConfig.workDirs.map { PodResolverPath(it + `lib/fan/`, fileCache) }
			)
		this.fpmConfig	= fpmConfig
		this.podFiles	= podFiles
		this.fileCache	= fileCache
	}
	
	Void addRemoteRepos() {
		localResolvers := PodResolvers(fpmConfig, podFiles, fileCache)
		resolvers.addAll(
			fpmConfig.fanrRepos.keys.map { PodResolverFanrRemote(fpmConfig, it, 5, localResolvers) }
		)
	}
	
	PodVersion[] resolve(Depend dependency) {
		depends.getOrAdd(dependency) |->PodVersion[]| {
			
			// first lets check if this dependency 'fits' into any existing
			// we don't want to contact remote fanr repos if we don't have to
			existing := depends.find |vers, dep->Bool| { Utils.dependFits(dependency, dep) }
			
			if (existing != null) {
				// only return what we need
				return existing.findAll { dependency.match(it.version) }
			}
			
			// naa, lets do the full resolve hog
			// TODO when 'unique-ing' ensure local podVersions trump remote ones 
			return resolvers.map { it.resolve(dependency) }.flatten.unique
		}
	}
	
	Str:PodFile resolveAll(Str:PodFile podFiles) {
		resolvers.map { it.resolveAll }.flatten.each |PodVersion podVer| {
			if (podFiles.containsKey(podVer.name).not)
				podFiles[podVer.name] = podVer.toPodFile
		}
		return podFiles
	}
}

internal mixin PodResolver {
	abstract PodVersion[] resolve(Depend dependency)
	abstract PodVersion[] resolveAll()
}

internal class PodResolverFanrLocal : PodResolver {
	private static const Regex	podRegex	:= "(.+)-(.+)\\.pod".toRegex

	FileCache	fileCache
	File 		repoDir

	new make(File repoDir, FileCache fileCache) {
		this.repoDir	= repoDir
		this.fileCache	= fileCache
	}

	override PodVersion[] resolve(Depend dependency) {
		podDir := repoDir.plus(dependency.name.toUri.plusSlash, true)
		return podDir.listFiles(podRegex).map |file->PodVersion?| {
			podName := PodName(file)
			if (podName == null)
				return null

			if (podName.name != dependency.name)
				return null

			if (!dependency.match(podName.ver))
				return null
			
			return fileCache.get(file)

		}.exclude { it == null }
	}
	
	override PodVersion[] resolveAll() {
		repoDir.listDirs.map |repoDir->PodName?| {
			repoDir.listFiles(podRegex).map { PodName(it) }.exclude { it == null }.sort.last
		}.exclude { it == null }.map |PodName pod->PodVersion| { fileCache.get(pod.file) }
	}
}

internal class PodName {
	private static const Regex	podRegex	:= "(.+)-(.+)\\.pod".toRegex

	Str		name
	Version	ver
	File	file

	static new makeFromFile(File file) {
		matcher := podRegex.matcher(file.name)
		if (!matcher.find)
			return null

		name	:= matcher.group(1)
		version := Version(matcher.group(2), false)

		if (version == null)
			return null

		return PodName {
			it.file = file
			it.name = name
			it.ver	= version
		}
	}
	new make(|This|in) { in(this) }
	
	override Int compare(Obj that) {
		ver <=> (that as PodName).ver
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

	override PodVersion[] resolveAll() {
		pathDir.listFiles(Regex.glob("*.pod")).map { fileCache.get(it) }.exclude { it == null }
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
			if (dependency.name != podVersion.name || dependency.match(podVersion.version).not)
				podVersion = null
		
		return podVersion == null ? PodVersion#.emptyList : [podVersion]
	}
	
	override PodVersion[] resolveAll() {
		fileCache.get(podFile) ?: PodVersion#.emptyList
	}
}

internal class PodResolverFanrRemote : PodResolver {
	Repo	repo
	Str		repoName
	Int		numVersions
	PodResolvers localResolvers

	new make(FpmConfig fpmConfig, Str repoName, Int numVersions, PodResolvers localResolvers) {
		this.repo 		 	= fpmConfig.fanrRepo(repoName)
		this.repoName	 	= repoName
		this.numVersions 	= numVersions
		this.localResolvers	= localResolvers
	}

	override PodVersion[] resolve(Depend dependency) {
		latest := localResolvers.resolve(dependency).sort.last
		echo("Querying ${repoName} for ${dependency} ( > $latest.version)")
		specs := repo.query(dependency.toStr, numVersions)
		vers  := specs
			.findAll |PodSpec spec->Bool| {
				spec.version > latest.version
			}
			.map |PodSpec spec->PodVersion| {
				PodVersion(`fanr://${repoName}/${dependency}`, spec)
			}.sort as PodVersion[]
		if (vers.size > 0)
			echo("  Found ${dependency.name} " + vers.join(", ") { it.version.toStr })
		return vers
	}

	// only used for local resolution
	override PodVersion[] resolveAll() { PodVersion#.emptyList }
}
