
internal class BuildPodRepository : Repository {
	override Str		name 
	override Bool		isLocal	:= true
	private  Depend[]	dependsOn
	
	new make(Str name, Depend[] dependsOn) {
		this.name		= name
		this.dependsOn	= dependsOn
	}

	override Uri		url			()					{ `build:${name}` }
	override Depend[]	dependencies(PodFile podFile)	{ dependsOn }
	override Void		upload		(PodFile podFile)	{ throw UnsupportedErr() }
	override File		download	(PodFile podFile)	{ throw UnsupportedErr() }
	override Void		delete		(PodFile podFile)	{ throw UnsupportedErr() }
	override PodFile[]	resolve		(Depend depend)		{ throw UnsupportedErr() }
	override PodFile[]	resolveAll	()					{ throw UnsupportedErr() }
}
