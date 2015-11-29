
const class PodConstraint {
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
