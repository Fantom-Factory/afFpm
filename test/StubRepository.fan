
const class StubRepository : Repository {
	
	private  const LocalRef	podsRef	:= LocalRef(#pods.qname) |->Obj?| { PodFile[,] }
	private  PodFile[]	pods()		{ podsRef.val }
	
	override const Str	name	:= "StubRepo"
	override const Uri	url		:= `stubrepo`
	override const Bool	isLocal	:= true
	
	override File download		(PodFile podFile)	{ Buf().toFile(podFile.url) }
	override Void upload		(PodFile podFile)	{ throw UnsupportedErr() }
	override Void delete		(PodFile podFile)	{ throw UnsupportedErr() }
	
	override PodFile[]	resolveAll() { pods }
	
	override PodFile[]	resolve	(Depend depend, Str:Obj? options) {
		pods.findAll { it.fits(depend) }
	}
	
	Void add(Str dependency, Str? dependents) {
		pod 		:= Depend(dependency.replace("@", " "))
		dependsOn	:= dependents == null ? Depend#.emptyList : dependents.split(',').exclude { it.isEmpty }.map { Depend(it, true) }
		pods.add(PodFile(pod.name, pod.version, dependsOn, `stub:${dependency}`, this))
	}
}
