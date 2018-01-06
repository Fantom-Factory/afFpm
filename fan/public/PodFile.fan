
** Represents a pod version with a backing file.
abstract class PodFile {

	** The name of this pod.
	const Str		name
	
	** The version of this pod.
	const Version	version
	
	** Absolute URL where the pod is located.
	const Uri		url
	
	Repository	repository {
		private set
	}
	
	internal new make(|This|in) { in(this) }
	
	** The backing file for this pod.
	** If the pod has a remote location, this will download it to a local / memory representation.
	File file() {
		repository.download(this)
	}
	
	Void delete() {
		repository.delete(this)
	}
	
	Void installTo(Repository repository) {
		repository.upload(this)		
	}
	
	** This pod version expressed as a dependency.
	** Convenience for:
	** 
	**   syntax: fantom
	**   Depend("$name $version")
	Depend asDepend() {
		Depend("$name $version")
	}

	@NoDoc override Str toStr() 			{ "$name $version - $url" }
	@NoDoc override Int hash() 				{ url.hash }
	@NoDoc override Bool equals(Obj? that)	{ (that as PodFile)?.url == url }
}