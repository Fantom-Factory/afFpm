
class StubRepository : Repository {
	
	private PodFile[]		pods		:= [,]
	
	override Str	name	:= "StubRepo"
	override Uri	url		:= `stubrepo`
	override Bool	isLocal	:= true
	
	internal override Void upload		(PodFile podFile)	{ throw UnsupportedErr() }
	internal override File download		(PodFile podFile)	{ throw UnsupportedErr() }
	internal override Void delete		(PodFile podFile)	{ throw UnsupportedErr() }
	
	override PodFile[]	resolveAll() { pods }
	
	internal override PodFile[]	resolve	(Depend depend) 	{
		pods.findAll { it.fits(depend) }
	}
	
	Void add(Str dependency, Str? dependents := null) {
		pod 		:= Depend(dependency.replace("@", " "))
		dependsOn	:= dependents?.split(',')?.map { Depend(it) } ?: Depend#.emptyList
		pods.add(PodFile(pod.name, pod.version, dependsOn, `stub:${dependency}`, this))
	}
}
