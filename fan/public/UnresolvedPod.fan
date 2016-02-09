
** Details of a pod that could not be resolved.
const class UnresolvedPod {
	
	** The name of the pod that couldn't be resolved.
	const Str 				name
	
	** A list of pod versions that are available. 
	const Version[]			available
	
	** The committee of 'PodConstraints' that couldn't make up their minds as to which pod version they required!
	const PodConstraint[]	committee
	
	@NoDoc
 	new make(|This| in) { in(this) }

	@NoDoc
	override Str toStr() {
		availStr := available.isEmpty ? "Not found" : available.join(", ")
		return "Could not resolve ${name} (${availStr})\n" + committee.join("") { "  ${it}\n" }
	}
}
