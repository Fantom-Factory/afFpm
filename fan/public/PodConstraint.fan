
internal const class GroupConstraint {
	internal const PodVersion	pVersion
			 const Depend		dependsOn

	Str podName() {
		pVersion.name
	}

	Version podVersion() {
		pVersion.version
	}

	@NoDoc
	override Str toStr() {
		"${podName}@${podVersion} -> ${dependsOn}"
	}
	
 	new make(|This|? in) { in?.call(this) }
}

@Serializable
internal const class PodConstraint {
	internal const PodVersion	pVersion
			 const Depend		dependsOn

	Str podName() {
		pVersion.name
	}

	Version podVersion() {
		pVersion.version
	}

	@NoDoc
	override Str toStr() {
		"${podName}@${podVersion} -> ${dependsOn}"
	}
	
 	new make(|This|? in) { in?.call(this) }
}

const class UnresolvedPod {
	const Str 		name
	const Version	version
	const Depend	dependsOn	// what can't be resolved
	const Version[]	available

	@NoDoc
	override Str toStr() {
		availStr := available.isEmpty ? "Not found" : available.join(", ")
		return "${name}@${version} -> ${dependsOn} (${availStr})"
	}
	
 	new make(|This| in) { in(this) }
}

