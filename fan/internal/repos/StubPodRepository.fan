
internal const class StubPodRepository : Repository {
	override const Str		name	 	:= "Stub Repository"
	override const Uri		url			:= `stub:repo`
	override const Bool		isLocal		:= true
	override const Bool		isFanrRepo	:= false

	override PodFile	upload		(PodFile podFile)		{ throw UnsupportedErr() }
	override File		download	(PodFile podFile)		{ throw UnsupportedErr() }
	override Void		delete		(PodFile podFile)		{ throw UnsupportedErr() }
	override PodFile[]	resolve		(Depend d, Str:Obj? o)	{ throw UnsupportedErr() }
	override PodFile[]	resolveAll	()						{ throw UnsupportedErr() }
	override Void		cleanUp		()						{ }

	private new make() { }
	
	static const StubPodRepository instance	:= StubPodRepository()
}
