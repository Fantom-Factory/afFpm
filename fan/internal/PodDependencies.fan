
internal class PodDependencies {

	PodResolvers	podResolvers
	FileCache		fileCache		:= FileCache()
	PodNode[]		initNodes		:= PodNode[,]
	Str:PodNode		allNodes		:= Str:PodNode[:] { it.ordered = true }
	
	new make(FpmConfig config) {
		this.podResolvers	= PodResolvers(config, fileCache)
	}
	
	This addPod(Depend dependency) {
		podNode := resolveNode(dependency).pickLatestVersion
		if (podNode.podVersions.isEmpty)
			throw Err("Could not find pod file for '${dependency}'")
		initNodes.add(podNode)
		return this
	}
	
	This satisfyDependencies() {
		createProblemDomains
		
//		reduceDomain
//		pickLatestPods
		
		return this
	}
	
	Void createProblemDomains() {
		allNodes.vals.each { expandNode(it) }

		// brute force - try every permutation of pod versions and see which ones work
		
		
	}
	
	// see https://en.wikipedia.org/wiki/AC-3_algorithm
	Void reduceDomain(Str:PodNode podNodes) {
		constraints := (PodConstraint[]) podNodes.vals.map { it.toConstraints }.flatten
		worklist	:= constraints.dup

		while (worklist.isEmpty.not) {
			arc := worklist.pop
			if (arcReduce(arc, podNodes)) {
				destNode := podNodes[arc.depend.name]
				if (destNode.podVersions.isEmpty) {
					availableVersions := destNode._podVersions.map { version }.join(", ")
					causes := destNode.removalCauses.join(", ")
					throw Err("Could not resolve ${destNode.name} ${availableVersions} due to ${causes}")
					
				}
				else {
					// worklist := worklist + { (z, x) | z != y and there exists a relation R2(x, z) or a relation R2(z, x) }
					worklist.addAll(constraints.findAll { it.depend.name == arc.depend.name })
				}
			}
		}
	}
	
	Bool arcReduce(PodConstraint arc, Str:PodNode podNodes) {
		change := false
		
		destNode := podNodes[arc.depend.name]
		destNode.podVersions.each |dx| {
			if (arc.depend.match(dx.version).not) {
				destNode.removeVersion(dx, arc)
				change = true
			}
		}
		
		return change
	}
	
	
	// in the event multiple pods satisfy the dependencies, pick the latest ones
	Void pickLatestPods(Str:PodNode podNodes) {
		podNodes.each {
			echo(it.name + " : " + it.podVersions.map{version}.toStr)
		}
		podNodes.each { it.pickLatestVersion }
	}
	
	Void expandNode(PodNode node) {
		node.podVersions.each |podVersion| {
			podVersion.depends.each |depend| {
				innerNode := resolveNode(depend)
				expandNode(innerNode)
			}
		}
	}
	
	PodNode? resolveNode(Depend dependency) {
		allNodes.getOrAdd(dependency.name) {
			PodNode {
				it.name = dependency.name
			}
		}.addPodVersions(podResolvers.resolve(dependency))
	}	
	
	Str:PodFile getPodFiles() {
//		podNodes.map { it.toPodFile }
		[:]
	}
}


class PodNode {
	const 	Str				name
			PodVersion[]	_podVersions	:= PodVersion[,]
					Bool	expanded
		PodConstraint[]		removalCauses	:= PodConstraint[,]

	new make(|This|in) { in(this) }

	This pickLatestVersion() {
		picked := podVersions.sort.last
		_podVersions.each { it.deleted = (it != picked) }
		return this
	}
	
	This addPodVersions(PodVersion[] pods) {
		_podVersions = _podVersions.addAll(pods).unique.sort.reverse	// highest first
		return this
	}
	
	Void removeVersion(PodVersion podVersion, PodConstraint cause) {
		podVersion.deleted = true
		removalCauses.add(cause)
	}
	
	PodVersion[] podVersions() {
		_podVersions.findAll { it.deleted.not }
	}
	
	PodFile toPodFile() {
		if (podVersions.isEmpty)
			throw Err("No pod version found for ${name}")
		if (podVersions.size > 1)
			throw Err("Too many versions for ${name}")

		return PodFile {
			it.name 	= this.name
			it.version	= this.podVersions.first.version
			it.file		= this.podVersions.first.file
		}
	}

	PodConstraint[] toConstraints() {
		_podVersions.map { it.toConstraints(this) }.flatten
	}

	override Str toStr() 			{ name }
	override Int hash() 			{ name.hash }
	override Bool equals(Obj? that)	{ name == that?->name }
}

class PodVersion {
	const 	Str			name
	const 	Version		version
	const	Depend		depend
	const	File		file
	const	Depend[]	depends
			Bool		deleted

	new make(|This|in) { in(this) }

	new makeFromProps(File file, Str:Str metaProps) {
		this.file 		= file
		this.name		= metaProps["pod.name"]
		this.version	= Version(metaProps["pod.version"], true)
		this.depends	= metaProps["pod.depends"].split(';').map { Depend(it, false) }.exclude { it == null }
		this.depend		= Depend("${name} ${version}")
	}
	
	PodConstraint[] toConstraints(PodNode node) {
		depends.map |d| { PodConstraint { it.podNode = node; it.podVersion = this; it.depend = d } }
	}
	
	override Int compare(Obj that) {
		version <=> (that as PodVersion).version
	}

	override Str toStr() 			{ depend.toStr }
	override Int hash() 			{ depend.hash }
	override Bool equals(Obj? that)	{ depend == that?->depend }
}

class PodConstraint {
	PodNode		podNode
	PodVersion	podVersion
	Depend		depend
	
	override Str toStr() {
		"${podNode.name}@${podVersion.version} -> ${depend}"
	}
	
	new make(|This|in) { in(this) }
}