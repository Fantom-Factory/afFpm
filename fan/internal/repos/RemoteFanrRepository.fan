using fanr::Repo
using fanr::PodSpec

internal const class RemoteFanrRepository : Repository {
	private  const CorePods	corePods	:= CorePods()
	private	 const Repo		repo
	override const Str		name
	override const Uri		url
	override const Bool		isLocal		:= false

	new make(Str name, Uri url, Str? username, Str? password) {
		this.name	= name
		this.url	= url
		this.repo	= Repo.makeForUri(url, username, password)
	}

	override Void upload(PodFile podFile) {
		repo.publish(podFile.file)
	}
	
	override File download(PodFile podFile) {
		spec := repo.find(podFile.name, podFile.version, true)
		return repo.read(spec).readAllBuf.toFile(`fanr://${name}/${podFile.depend}`)
	}
	
	override Void delete(PodFile podFile) { throw UnsupportedErr() }

	override PodFile[] resolve(Depend depend, Str:Obj? options) {
		noCore  := (Bool) options.get("noCore",  false) 
		maxPods := (Int ) options.get("maxPods", 5)
		log     := (Log?) options.get("log")

		if (noCore && corePods.isCorePod(depend.name))
			return PodFile#.emptyList

		log?.info("Querying ${name} for ${depend}")
//		log?.info("Querying ${repoName} for ${dependency}" + ((latest == null) ? "" : " ( > $latest.version)"))
		specs := repo.query(depend.toStr, maxPods)
		files  := specs
//			.findAll |PodSpec spec->Bool| {
//				(latest == null) ? true : spec.version > latest.version
//			}
			.map |PodSpec spec->PodFile| {
				PodFile(spec.name, spec.version, spec.depends, `fanr://${name}/${depend}`, this)
			}.sort as PodFile[]

		if (files.size > 0)
			log?.info("Found ${depend.name} " + files.join(", ") { it.version.toStr })

		return files
	}
	
	override PodFile[] resolveAll() {
		// should only be called on local repos
		throw UnsupportedErr("fanr does not support pod deletion")
	}
}