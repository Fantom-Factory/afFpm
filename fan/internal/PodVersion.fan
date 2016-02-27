using fanr::PodSpec

// will be useful for public APIs.
** Represents a specific version of a pod.
@Serializable
internal const class PodVersion {
	
	** The name of this pod.
	const 	Str			name
	
	** The version of this pod.
	const 	Version		version
	
	** Where the pod is located.
	** May have a local 'file:' or a remote 'fanr:' scheme.
	const	Uri?		url

	** The dependencies of this pod
	const	Depend[]	depends
	
	internal const	PodConstraint[]	constraints
	internal const	Depend			depend	// convenience for Depend("${name} ${version}")
	internal const	Str				dependsHash

	internal new makeForTesting(|This|in) {
		in(this)
		this.depend		 = Depend("${name} ${version}")
		this.constraints = depends.map |d| { PodConstraint { it.pod = depend; it.dependsOn = d } }
		this.dependsHash = depends.dup.sort.join(" ")
	}

	internal new makeFromPodSpec(Uri url, PodSpec spec) {
		this.url 		= url
		this.name		= spec.name
		this.version	= spec.version
		this.depends	= spec.depends
		this.depend		= Depend("${name} ${version}")
		this.constraints= depends.map |d| { PodConstraint { it.pod = depend; it.dependsOn = d } }
		this.dependsHash= depends.dup.sort.join(" ")
	}

	internal new makeFromProps(File? file, Str:Str metaProps) {
		this.url 		= file?.uri
		this.name		= metaProps["pod.name"]
		this.version	= Version(metaProps["pod.version"], true)
		this.depends	= metaProps["pod.depends"].split(';').map { Depend(it, false) }.exclude { it == null }
		this.depend		= Depend("${name} ${version}")
		this.constraints= depends.map |d| { PodConstraint { it.pod = depend; it.dependsOn = d } }
		this.dependsHash= depends.dup.sort.join(" ")
	}
	
	** Returns this 'PodVersion' instance as a 'PodFile'
	PodFile toPodFile() {
		PodFile {
			it.name 	= this.name
			it.version	= this.version
			it.url		= this.url
		}
	}

	@NoDoc
	override Int compare(Obj that) {
		version <=> (that as PodVersion).version
	}

	@NoDoc	override Str toStr() 			{ depend.toStr }
	@NoDoc	override Int hash() 			{ depend.hash }
	@NoDoc	override Bool equals(Obj? that)	{ depend == that?->depend }
}
