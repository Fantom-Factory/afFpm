
const class StubRepository : Repository {
	
	private  const LocalRef	podsRef	:= LocalRef(#pods.qname) |->Obj?| { PodFile[,] }
	private  PodFile[]	pods()		{ podsRef.val }
	
	override const Str	name	:= "StubRepo"
	override const Uri	url		:= `stubrepo`
	override const Bool	isLocal	:= true
	
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
