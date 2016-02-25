
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

