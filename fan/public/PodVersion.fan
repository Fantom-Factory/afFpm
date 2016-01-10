
// will be useful for public APIs.
** Represents a specific version of a pod.
const class PodVersion {
	** The name of the pod.
	const 	Str				name
	
	** The version of the pod.
	const 	Version			version
	
	** The backing file of this pod.
	const	File?			file
	
	** The dependencies of this pod
	const	Depend[]		depends
	
	internal const	PodConstraint[]	constraints
	internal const	Depend			depend	// convenience for Depend("${name} ${version}")

	new make(|This|in) {
		in(this)
		this.constraints = depends.map |d| { PodConstraint { it.pVersion = this; it.dependsOn = d } }		
	}

	new makeFromProps(File? file, Str:Str metaProps) {
		this.file 		= file
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
			it.file		= this.file
		}
	}

	override Int compare(Obj that) {
		version <=> (that as PodVersion).version
	}

	override Str toStr() 			{ depend.toStr }
	override Int hash() 			{ depend.hash }
	override Bool equals(Obj? that)	{ depend == that?->depend }
}
