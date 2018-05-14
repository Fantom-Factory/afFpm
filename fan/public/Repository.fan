
const mixin Repository {

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

