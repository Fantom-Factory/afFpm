
internal const class StubPodRepository : Repository {
	override const Str		name 
	override const Bool		isLocal	:= true
	
	new make(Str name) {
		this.name		= name
	}

	override Uri		url			()					{ `stub:${name}` }
	override Void		upload		(PodFile podFile)	{ throw UnsupportedErr() }
	override File		download	(PodFile podFile)	{ throw UnsupportedErr() }
	override Void		delete		(PodFile podFile)	{ throw UnsupportedErr() }
	override PodFile[]	resolve		(Depend depend)		{ throw UnsupportedErr() }
	override PodFile[]	resolveAll	()					{ throw UnsupportedErr() }
}
