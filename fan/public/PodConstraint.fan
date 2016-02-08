
const class PodConstraint {
	const Depend	pod
	const Depend	dependsOn

	Str name() {
		pod.name
	}

	Version version() {
		pod.version
	}

	@NoDoc
	override Str toStr() {
		"${name}@${version} -> ${dependsOn}"
	}
	
	override Int compare(Obj that) {
		pod.name <=> (that as PodConstraint).pod.name
	}
	
 	new make(|This|? in) { in?.call(this) }
}

const class UnresolvedPod {
	const Str 				name		// what can't be resolved
	const Version[]			available
	const PodConstraint[]	committee	// 'cos they can't decide the outcome!
	
 	new make(|This| in) { in(this) }

	@NoDoc
	override Str toStr() {
		availStr := available.isEmpty ? "Not found" : available.join(", ")
		return "Could not resolve ${name} (${availStr})\n" + committee.join("") { "  ${it}\n" }
	}
}

