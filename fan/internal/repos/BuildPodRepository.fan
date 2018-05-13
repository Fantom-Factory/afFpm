
internal class BuildPodRepository : Repository {
	override Str		name 
	override Bool		isLocal	:= true
	
	new make(Str name) {
		this.name		= name
	}

	override Uri		url			()					{ `build:${name}` }
	override Void		upload		(PodFile podFile)	{ throw UnsupportedErr() }
	override File		download	(PodFile podFile)	{ throw UnsupportedErr() }
	override Void		delete		(PodFile podFile)	{ throw UnsupportedErr() }
	override PodFile[]	resolve		(Depend depend)		{ throw UnsupportedErr() }
	override PodFile[]	resolveAll	()					{ throw UnsupportedErr() }
}