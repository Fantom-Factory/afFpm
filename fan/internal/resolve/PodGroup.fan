
** A collection of pods that share the same dependencies.
internal class PodGroup {
	const Str				name
	const Depend[]			dependsOn
	const Str				dependsOnHash
	
	private PodFile:Bool	pods
	
	new make(PodFile pod) {
		this.name 			=  pod.name
		this.dependsOn		=  pod.dependsOn
		this.dependsOnHash	= dependsOn.dup.sort.join(" ")
		this.pods			= PodFile:Bool[pod:false]
	}
	
	Void add(PodFile pod) {
		pods[pod] = false
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
	
	PodFile latest() {
		// TODO optimise
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
	
	override Int hash() { dependsOnHash.hash }
	override Bool equals(Obj? obj) {
		that := obj as PodGroup
		return that.name == this.name && that.dependsOn == this.dependsOn
	}
}

