** Models a dependency from one pod to another.
const class PodConstraint {
	
	** The pod with the dependency. 
	** This is always a single, simple version, e.g. 'foo 1.2'
	const Depend	pod
	
	** The dependency. May be multiple and complex, e.g. 'bar 0.2-0.8, 1.1.2, 1.6+'
	const Depend	dependsOn
	
	@NoDoc
 	new make(|This|? in) { in?.call(this) }

	@NoDoc
	override Str toStr() {
		"${pod.name}@${pod.version} -> ${dependsOn}"
	}
	
	@NoDoc
	override Int compare(Obj that) {
		pod.name <=> (that as PodConstraint).pod.name
	}
}