using fanr::PodSpec

internal class PodGroup {
	Str				name
	Depend[]		depends
	Str				dependsHash
	
	private PodVersion:Bool	pods
	
	new make(PodVersion podVer) {
		this.name 			=  podVer.name
		this.depends		=  podVer.depends
		this.dependsHash	= depends.dup.sort.join(" ")
		this.pods			= PodVersion:Bool[podVer:false]
	}
	
	Void add(PodVersion podVer) {
		pods[podVer] = false
	}

	Void reset() {
		pods.each |val, key| { pods[key] = false }
	}

	Bool noMatch(Depend dependsOn) {
		fail := true
		// pods.all() will *not* iterate through all the keys if false is returned
		pods.each |val, key| {
			if (val == true)
				return
			out := dependsOn.match(key.version).not
			if (out)
				pods[key] = true
			else
				fail = false
		}
		return fail
	}
	
	PodVersion latest() {
		pods.exclude { it }.keys.sort.last
	}
	
	PodConstraint[] constraints() {
		return pods.keys.first.constraints
	}

	private Version[] versions() {
		pods.keys.map { it.version  }
	}

	
	
	
	override Str toStr() {
		name + " " + versions.join(", ")
	}
	
	override Int hash() { dependsHash.hash }
	override Bool equals(Obj? obj) {
		that := obj as PodGroup
		return that.name == this.name && that.depends == this.depends
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
