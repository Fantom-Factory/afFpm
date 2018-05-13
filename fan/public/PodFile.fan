
** Represents a pod backed by a repository.
class PodFile {

	** The name of this pod.
	const Str		name
	
	** The version of this pod.
	const Version	version
	
	** Absolute URL where the pod is located.
	const Uri		url
	
	** This pod version expressed as a dependency.
	const Depend	depend

	** The repository where this pod file is held.
	Repository		repository { private set }
	
	** Internal ctor
	@NoDoc
	new make(Str name, Version version, Uri url, Repository repository) {
		this.name		= name
		this.version	= version
		this.url		= url
		this.depend		= Depend("$name $version")
		this.repository	= repository
	}
	
	** The backing file for this pod.
	** If the pod has a remote location, this will download it to a local / memory representation.
	File file() {
		repository.download(this)
	}
	
	** Deletes this pod from its owning repository.
	Void delete() {
		repository.delete(this)
	}
	
	** Installs this pod in to the given repository.
	Void installTo(Repository repository) {
		repository.upload(this)
	}

	** Returns the dependencies of this pod.
	Depend[] dependsOn() {
		repository.dependencies(this)
	}
	
	** Returns 'true' if this *fits* the given dependency.
	Bool fits(Depend depend) {
		depend.name == this.name && depend.match(this.version)
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
