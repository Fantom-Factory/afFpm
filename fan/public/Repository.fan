
mixin Repository {

	abstract Str name()
	abstract Uri url()
	
	PodFile[] find(Depend depends) {
		throw UnsupportedErr()
	}
	
	internal abstract Void		upload			(PodFile podFile)
	internal abstract File		download		(PodFile podFile)
	internal abstract Void		delete			(PodFile podFile)
	
	internal abstract PodFile[]	resolveAll		()
	internal abstract PodFile[]	resolve			(Depend depend)
	internal abstract Bool		isLocal			()
	
	@NoDoc override Int hash() 				{ url.hash }
	@NoDoc override Bool equals(Obj? that)	{ (that as Repository)?.url == url }
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
}
