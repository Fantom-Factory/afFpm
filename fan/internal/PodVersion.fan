
internal const class PodVersion {
	const 	Str				name
	const 	Version			version
	const	Depend			depend	// convenience for Depend("${name} ${version}")
	const	File?			file
	const	Depend[]		depends
	const	PodConstraint[]	constraints

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
