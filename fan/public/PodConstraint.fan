
//internal const class GroupConstraint {
//	internal const PodVersion	pVersion
//			 const Depend		dependsOn
//
//	Str podName() {
//		pVersion.name
//	}
//
//	Version podVersion() {
//		pVersion.version
//	}
//
//	@NoDoc
//	override Str toStr() {
//		"${podName}@${podVersion} -> ${dependsOn}"
//	}
//	
// 	new make(|This|? in) { in?.call(this) }
//}

//@Serializable
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
	
 	new make(|This|? in) { in?.call(this) }
}

const class UnresolvedPod {
	const Str 				name		// what can't be resolved
	const Version[]			available
	const PodConstraint[]	committee	// 'cos they can't decide the outcome!

	@NoDoc
	override Str toStr() {
		availStr := available.isEmpty ? "Not found" : available.join(", ")
		return "Could not resolve ${name} (${availStr})\n" + committee.join("") { "  ${it}\n" }
	}
	
 	new make(|This| in) { in(this) }
}

