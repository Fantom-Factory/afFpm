using fanr::PodSpec

// will be useful for public APIs.
** Represents a specific version of a pod.
const class PodVersion {
	** The name of the pod.
	const 	Str			name
	
	** The version of the pod.
	const 	Version		version
	
//	** The backing file of this pod.
//	const	File?		file
	
	** The location of this pod.
	** Valid schemes are: file and fanr
	const	Uri?		url

	** The dependencies of this pod
	const	Depend[]	depends
	
	internal const	PodConstraint[]	constraints
	internal const	Depend			depend	// convenience for Depend("${name} ${version}")

	
	internal new makeForTesting(|This|in) {
		in(this)
		this.depend		 = Depend("${name} ${version}")
		this.constraints = depends.map |d| { PodConstraint { it.pVersion = this; it.dependsOn = d } }		
	}

	internal new makeFromPodSpec(Uri url, PodSpec spec) {
		this.url 		= url
		this.name		= spec.name
		this.version	= spec.version
		this.depends	= spec.depends
		this.depend		= Depend("${name} ${version}")
		this.constraints= depends.map |d| { PodConstraint { it.pVersion = this; it.dependsOn = d } }
	}

	internal new makeFromProps(File? file, Str:Str metaProps) {
		this.url 		= file?.uri
		this.name		= metaProps["pod.name"]
		this.version	= Version(metaProps["pod.version"], true)
		this.depends	= metaProps["pod.depends"].split(';').map { Depend(it, false) }.exclude { it == null }
		this.depend		= Depend("${name} ${version}")
		this.constraints= depends.map |d| { PodConstraint { it.pVersion = this; it.dependsOn = d } }
	}
	
	PodFile toPodFile() {
		PodFile {
			it.name 	= this.name
			it.version	= this.version
			it.url		= this.url
		}
	}

	override Int compare(Obj that) {
		version <=> (that as PodVersion).version
	}

	override Str toStr() 			{ depend.toStr }
	override Int hash() 			{ depend.hash }
	override Bool equals(Obj? that)	{ depend == that?->depend }
}
