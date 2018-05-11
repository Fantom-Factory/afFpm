
** Represents a pod version with a backing file.
class PodFile {

	** The name of this pod.
	const Str		name
	
	** The version of this pod.
	const Version	version
	
	** Absolute URL where the pod is located.
	const Uri		url
	
	** This pod version expressed as a dependency.
	const Depend	depend

	** The repository where this Pod file is held.
	Repository		repository { private set }
	
	internal new make(|This|in) {
		in(this)
		this.depend	= Depend("$name $version")
	}
	
	internal new makeFields(Str name, Version version, Uri url, Repository repository) {
		this.name		= name
		this.version	= version
		this.url		= url
		this.depend		= Depend("$name $version")
		this.repository	= repository
	}
	
	** The backing file for this pod.
	** If the pod has a remote location, this will download it to a local / memory representation.
	File file() {
		// TODO cache
		repository.download(this)
	}
	
	Void delete() {
		repository.delete(this)
	}
	
	Void installTo(Repository repository) {
		repository.upload(this)		
	}

	Depend[] dependsOn() {
		// TODO cache
		repository.dependencies(this)
	}
	
	@NoDoc override Str toStr() 			{ "$name $version - $url" }
	@NoDoc override Int hash() 				{ url.hash }
	@NoDoc override Bool equals(Obj? that)	{ (that as PodFile)?.url == url }
	
	@NoDoc
	override Int compare(Obj obj) {
		that := obj as PodFile
		return this.name == that.name
			? this.version <=> that.version
			: this.name    <=> that.name
	}
}
