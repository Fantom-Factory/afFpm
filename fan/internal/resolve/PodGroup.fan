
** A collection of pods that share the same dependencies.
internal class PodGroup {
	const Str				name
	const Depend[]			dependsOn
	const Str				dependsOnHash
		  PodConstraint[]?	_constraints
	
	private PodFile[]		pods
	private Depend:Bool		matched
	
	new make(PodFile pod) {
		this.name 			=  pod.name
		this.dependsOn		=  pod.dependsOn
		this.dependsOnHash	= dependsOn.dup.sort.join(" ")
		this.matched		= Depend:Bool[pod.depend:false]
		this.pods			= PodFile[pod]
	}
	
	Void add(PodFile pod) {
		matched[pod.depend] = false
		pods.add(pod)
	}

	Void reset() {
		matched.each |val, key| { matched[key] = false }
	}

	Bool noMatch(Depend dependsOn) {
		fail := true
		// pods.all() will *not* iterate through all the keys if false is returned
		matched.each |val, key| {
			if (val == true)
				return
			out := dependsOn.match(key.version).not
			if (out)
				matched[key] = true
			else
				fail = false
		}
		return fail
	}
	
	PodFile latest() {
		depend := matched.exclude { it }.keys.max
		return pods.find { it.depend == depend } 
	}
	
	PodConstraint[] constraints() {
		if (_constraints == null) {
			pod := pods.first
			_constraints = pod.dependsOn.map |dependsOn| {
				PodConstraint {
					it.pod			= pod.depend
					it.dependsOn	= dependsOn
				}
			}
		}
		return _constraints
	}

	private Version[] versions() {
		matched.keys.map { it.version  }
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

