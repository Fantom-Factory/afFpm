
mixin Repository {

	abstract Str name()
	abstract Uri url()
	
	// ????
	abstract Void read()
	
	PodFile[] find(Depend depends) {
		throw UnsupportedErr()
	}
	
	internal abstract Void		upload(PodFile podFile)
	internal abstract File		download(PodFile podFile)
	internal abstract Void		delete(PodFile podFile)
	internal abstract PodFile[]	resolve(Depend depend)
}

class LocalFileRepository : Repository {
	override Str	name
	override Uri	url
	
	new make(|This| f) { f(this) }

	override Void read() { }
	
	internal override Void upload(PodFile podFile) { }
	internal override File download(PodFile podFile) { throw UnsupportedErr() }
	internal override Void delete(PodFile podFile) { }
	internal override PodFile[]	resolve(Depend depend) { throw UnsupportedErr() }
}

class LocalFanrRepository : Repository {
	override Str	name
	override Uri	url
	
	new make(|This| f) { f(this) }

	override Void read() { }

	internal override Void upload(PodFile podFile) { }
	internal override File download(PodFile podFile) { throw UnsupportedErr() }
	internal override Void delete(PodFile podFile) { }
	internal override PodFile[]	resolve(Depend depend) { throw UnsupportedErr() }
}

class RemoteFanrRepository : Repository {
	override Str	name
	override Uri	url
	
	new make(|This| f) { f(this) }

	override Void read() { }

	internal override Void upload(PodFile podFile) { }
	internal override File download(PodFile podFile) { throw UnsupportedErr() }
	internal override Void delete(PodFile podFile) { }
	internal override PodFile[]	resolve(Depend depend) { throw UnsupportedErr() }
}
