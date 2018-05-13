
mixin Repository {

	abstract Str name()
	abstract Uri url()
	
	// ????
//	abstract Void read()
	
	PodFile[] find(Depend depends) {
		throw UnsupportedErr()
	}
	
	internal abstract Void		upload			(PodFile podFile)
	internal abstract File		download		(PodFile podFile)
	internal abstract Void		delete			(PodFile podFile)
	
	internal abstract PodFile[]	resolveAll		()
	internal abstract PodFile[]	resolve			(Depend depend)
	internal abstract Depend[]	dependencies	(PodFile podFile)	
	internal abstract Bool		isLocal			()
	
	@NoDoc override Int hash() 				{ url.hash }
	@NoDoc override Bool equals(Obj? that)	{ (that as Repository)?.url == url }
}

internal class SinglePodRepository : Repository {
	override Str	name
	override Uri	url
	override Bool	isLocal	:= true
	
	new make(File podFile) {
		this.name	= podFile.name
		this.url	= podFile.normalize.uri
	}

//	override Void read() { }
	
	override Void upload(PodFile podFile) { }
	override File download(PodFile podFile) { throw UnsupportedErr() }
	override Void delete(PodFile podFile) { }
	override PodFile[]	resolveAll() { throw UnsupportedErr() }
	override PodFile[]	resolve(Depend depend) { throw UnsupportedErr() }
	override Depend[] dependencies(PodFile podFile) { throw UnsupportedErr() }
}

internal class LocalDirRepository : Repository {
	override Str	name
	override Uri	url
	override Bool	isLocal	:= true
	
	new make(Str name, File dir) {
		this.name	= name
		this.url	= dir.normalize.uri
	}

//	override Void read() { }
	
	override Void upload(PodFile podFile) { }
	override File download(PodFile podFile) { throw UnsupportedErr() }
	override Void delete(PodFile podFile) { }
	override PodFile[]	resolveAll() { throw UnsupportedErr() }
	override PodFile[]	resolve(Depend depend) { throw UnsupportedErr() }
	override Depend[] dependencies(PodFile podFile) { throw UnsupportedErr() }
}

internal class LocalFanrRepository : Repository {
	override Str	name
	override Uri	url
	override Bool	isLocal	:= true
	
	new make(Str name, File dir) {
		this.name	= name
		this.url	= dir.normalize.uri
	}

//	override Void read() { }

	override Void upload(PodFile podFile) { }
	override File download(PodFile podFile) { throw UnsupportedErr() }
	override Void delete(PodFile podFile) { }
	override PodFile[]	resolveAll() { throw UnsupportedErr() }
	override PodFile[]	resolve(Depend depend) { throw UnsupportedErr() }
	override Depend[] dependencies(PodFile podFile) { throw UnsupportedErr() }
}

internal class RemoteFanrRepository : Repository {
	override Str	name
	override Uri	url
	override Bool	isLocal	:= false
	
	new make(Str name, Uri url, Str? username, Str? password) {
		this.name	= name
		this.url	= url
	}

//	override Void read() { }

	override Void upload(PodFile podFile) { }
	override File download(PodFile podFile) { throw UnsupportedErr() }
	override Void delete(PodFile podFile) { }
	override PodFile[]	resolveAll() { throw UnsupportedErr() }
	override PodFile[]	resolve(Depend depend) { throw UnsupportedErr() }
	override Depend[] dependencies(PodFile podFile) { throw UnsupportedErr() }
}
