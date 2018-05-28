using fanr::Repo
using fanr::PodSpec

internal const class RemoteFanrRepository : Repository {
	private  const CorePods	corePods	:= CorePods()
	private	 const Repo		repo
	override const Str		name
	override const Uri		url
	override const Bool		isLocal		:= false
	override const Bool		isFanrRepo	:= true

	new make(Str name, Uri url, Str? username := null, Str? password := null) {
		this.name	= name
		this.url	= url
		this.repo	= Repo.makeForUri(url, username, password)
		
		// TODO maybe online repos can switch themselves off if they find an error - so we can continue to operate without them
	}

	override PodFile upload(PodFile podFile) {
		repo.publish(podFile.file)
		return PodFile(podFile.name, podFile.version, podFile.dependsOn, `fanr://${podFile.name}/${podFile.depend}`, this)
	}
	
	override File download(PodFile podFile) {
		spec := repo.find(podFile.name, podFile.version, true)
		return repo.read(spec).readAllBuf.toFile(`fanr://${name}/${podFile.depend}`)
	}
	
	override Void delete(PodFile podFile) { throw UnsupportedErr() }

	override PodFile[] resolve(Depend depend, Str:Obj? options) {
		corePods := (Bool)		options.get("corePods",  false) 
		maxPods	 := (Int )		options.get("maxPods", 5)
		minVer	 := (Version?)	options.get("minVer", null)
		log		 := (Log?)		options.get("log")

		if (!corePods && this.corePods.isCorePod(depend.name))
			return PodFile#.emptyList

		log?.debug("Querying ${name} for ${depend}" + ((minVer == null) ? "" : " ( > $minVer)"))
		specs := repo.query(depend.toStr, maxPods)
		files  := specs
			.findAll |PodSpec spec->Bool| {
				(minVer == null) ? true : spec.version > minVer
			}
			.map |PodSpec spec->PodFile| {
				PodFile(spec.name, spec.version, spec.depends, `fanr://${name}/${depend}`, this)
			}.sort as PodFile[]

		if (files.size > 0)
			log?.info(" - found ${depend.name} " + files.join(", ") { it.version.toStr })

		return files
	}
	
	override PodFile[] resolveAll() {
		// should only be called on local repos
		throw UnsupportedErr("fanr does not support pod deletion")
	}

	override Void cleanUp() { }
}