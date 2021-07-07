
** A collection of pods that share the same dependencies.
internal class PodGroup {
	const Str				name
	const Depend[]			dependsOn
	const Str				dependsOnHash
		  PodConstraint[]?	_constraints
	
	private PodFile[]		pods
	private Depend:Bool?	matched
	
	new make(PodFile pod) {
		this.name 			=  pod.name
		this.dependsOn		=  pod.dependsOn
		this.dependsOnHash	= dependsOn.dup.sort.join(" ")
		this.matched		= Depend:Bool?[pod.depend:null]
		this.pods			= PodFile[pod]
	}
	
	Void add(PodFile pod) {
		matched[pod.depend] = null
		pods.add(pod)
	}

	Void reset() {
		// each() is *much* faster than map()
		matched.each(resetFn)
	}
	private |Bool?, Depend| resetFn := |Bool? val, Depend key| { matched[key] = null }

	Bool matches(Depend dependsOn) {
		anyMatch := false
		matched.each |val, key| {
			// if we already know it doesn't match, don't bother re-match()-ing
			if (val != null) return
			match := dependsOn.match(key.version)
			if (match)
				anyMatch = true
			else
				matched[key] = false
		}
		return anyMatch
	}

	PodFile latest() {
		depend := matched.findAll { it != false }.keys.max
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

	Version[] versions() {
		matched.keys.map { it.version  }
	}
	
	override Str toStr() {
		name + " " + versions.join(", ")
	}
	
	override Int hash() { dependsOnHash.hash }
	override Bool equals(Obj? obj) {
		that := obj as PodGroup
		return that.name == this.name && that.dependsOnHash == this.dependsOnHash
	}
}

