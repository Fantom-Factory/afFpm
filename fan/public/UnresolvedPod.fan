
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

	** Dumps debug output to a string.
	Str dump() {
		avail	:= available.isEmpty ? "Not found" : available.join(", ")
		output	:= "  ${name} (${avail})\n"
		max		:= committee.reduce(0) |Int size, con| {
			size.max(con.pod.name.size + 1 + con.pod.version.toStr.size + 1)
		} as Int
		committee.each {
			output	+= "    " + "${it.pod.name}@${it.pod.version} ".padr(max, '-') + "-> ${it.dependsOn}\n"
		}
		return output
	}
	
	** Returns true if, actually, all the constraints can be satisfied by a single pod version!
	internal Bool isDodgy() {
		available.any |ver| {
			committee.all |mem| {
				mem.dependsOn.match(ver) 				
			}
		}
	}
	
	@NoDoc
	override Str toStr() {
		availStr := available.isEmpty ? "Not found" : available.join(", ")
		return "Could not resolve ${name} (${availStr})\n" + committee.join("") { "  ${it}\n" }
	}
}
