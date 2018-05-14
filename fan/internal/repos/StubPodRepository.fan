
internal const class StubPodRepository : Repository {
	override const Str		name 	:= "Stub Repository"
	override const Uri		url		:= `stub:repo`
	override const Bool		isLocal	:= true
	
	override Void		upload		(PodFile podFile)	{ throw UnsupportedErr() }
	override File		download	(PodFile podFile)	{ throw UnsupportedErr() }
	override Void		delete		(PodFile podFile)	{ throw UnsupportedErr() }
	override PodFile[]	resolve		(Depend depend)		{ throw UnsupportedErr() }
	override PodFile[]	resolveAll	()					{ throw UnsupportedErr() }
	
	private new make() { }
	
	static const StubPodRepository instance	:= StubPodRepository()
}
