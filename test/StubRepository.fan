
class StubRepository : Repository {
	
	private PodFile[]		pods		:= [,]
	private Depend:Depend[]	dependsOn	:= [:]
	
	override Str	name	:= "StubRepo"
	override Uri	url		:= `stubrepo`
	override Bool	isLocal	:= true
	
	internal override Void upload		(PodFile podFile)	{ throw UnsupportedErr() }
	internal override File download		(PodFile podFile)	{ throw UnsupportedErr() }
	internal override Void delete		(PodFile podFile)	{ throw UnsupportedErr() }
	
	override PodFile[]	resolveAll() { pods }
	
	internal override PodFile[]	resolve	(Depend depend) 	{
		pods.findAll { depend.name == it.name && depend.match(it.version) }
	}
	
	internal override Depend[] dependencies(PodFile podFile) { dependsOn[podFile.depend] }
	
	Void add(Str dependency, Str? dependents := null) {
		pod := Depend(dependency.replace("@", " "))
		pods.add(PodFile.makeFields(pod.name, pod.version, `stub:${dependency}`, this))
		depends	:= dependents?.split(',')?.map { Depend(it) } ?: Depend#.emptyList
		dependsOn[pod] = depends
	}
}
