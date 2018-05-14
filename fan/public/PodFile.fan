
** Represents a pod backed by a repository.
const class PodFile {

	** The name of this pod.
	const Str		name
	
	** The version of this pod.
	const Version	version
	
	** The dependencies of this pod.
	const Depend[]	dependsOn

	** Absolute URL of where this pod is located.
	const Uri		url
	
	// FIXME PodFile.url vs  PodFile.location

	** This pod's name and version expressed as a dependency.
	const Depend	depend

	** The repository where this pod file is held.
	const Repository repository
	
	** Internal ctor
	@NoDoc	// reserve make() for serialisation - if / when it happens!
	new makeFields(Str name, Version version, Depend[] dependsOn, Uri url, Repository repository) {
		this.name		= name
		this.version	= version
		this.dependsOn	= dependsOn
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
