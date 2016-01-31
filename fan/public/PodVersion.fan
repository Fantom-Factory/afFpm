using fanr::PodSpec

internal class PodGroup {
	Str				name
	Depend[]		depends
	PodVersion:Bool	podVersions
	Str				dependsHash
	
	new make(PodVersion podVer) {
		this.name 		=  podVer.name
		this.depends	=  podVer.depends
		this.podVersions= [podVer:true]
		this.dependsHash= depends.dup.sort.join(" ")
	}
	
	PodConstraint[] constraints() {
		podVersions.keys.first.constraints
	}
	
	Void reset() {
		podVersions.each |val, key| { podVersions[key] = true }
	}
	
	Void select(Depend dependsOn) {
		podVersions.each |val, podVer| {
			if (val == true) {
//				echo("$dependsOn match $podVer.version = ${dependsOn.match(podVer.version)}")
				podVersions[podVer] = dependsOn.match(podVer.version)
			}
		}
	}
	
	Version[] versions() {
		podVersions.keys.map { it.version }
	}
	
	PodVersion latest() {
		podVersions.findAll { it == true}.keys.sort.last
	}

	override Str toStr() {
		name + " " + podVersions.keys.sort.map { it.version }.join(" ")
	}
}


// will be useful for public APIs.
** Represents a specific version of a pod.
@Serializable
const class PodVersion {
	** The name of the pod.
	const 	Str			name
	
	** The version of the pod.
	const 	Version		version
	
	** The location of this pod.
	** Valid schemes are: file and fanr
	const	Uri?		url

	** The dependencies of this pod
	const	Depend[]	depends
	
	@Transient
	internal const	PodConstraint[]	constraints
	@Transient
	internal const	Depend			depend	// convenience for Depend("${name} ${version}")
	@Transient
	internal const	Str				dependsHash

	new make(|This|in) {
		in(this)
		this.depend		 = Depend("${name} ${version}")
		this.constraints = depends.map |d| { PodConstraint { it.pVersion = this; it.dependsOn = d } }
		this.dependsHash = depends.dup.sort.join(" ")		
	}
	
	internal new makeForTesting(|This|in) {
		in(this)
		this.depend		 = Depend("${name} ${version}")
		this.constraints = depends.map |d| { PodConstraint { it.pVersion = this; it.dependsOn = d } }
		this.dependsHash = depends.dup.sort.join(" ")
	}

	internal new makeFromPodSpec(Uri url, PodSpec spec) {
		this.url 		= url
		this.name		= spec.name
		this.version	= spec.version
		this.depends	= spec.depends
		this.depend		= Depend("${name} ${version}")
		this.constraints= depends.map |d| { PodConstraint { it.pVersion = this; it.dependsOn = d } }
		this.dependsHash= depends.dup.sort.join(" ")
	}

	internal new makeFromProps(File? file, Str:Str metaProps) {
		this.url 		= file?.uri
		this.name		= metaProps["pod.name"]
		this.version	= Version(metaProps["pod.version"], true)
		this.depends	= metaProps["pod.depends"].split(';').map { Depend(it, false) }.exclude { it == null }
		this.depend		= Depend("${name} ${version}")
		this.constraints= depends.map |d| { PodConstraint { it.pVersion = this; it.dependsOn = d } }
		this.dependsHash= depends.dup.sort.join(" ")
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
