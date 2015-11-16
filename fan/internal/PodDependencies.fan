
internal class PodDependencies {

	PodResolvers	podResolvers
	FileCache		fileCache		:= FileCache()
	PodNode[]		initNodes		:= PodNode[,]
	Str:PodNode		allNodes		:= Str:PodNode[:] { it.ordered = true }
	[Str:PodFile]?	podFiles
	
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
		allNodes.vals.each { expandNode(it) }
		finNodes := ([Str:PodNode]?) null

		// brute force - try every permutation of pod versions and see which ones work		
		nos := (PodNode[][]) allNodes.vals.map { it.permutate }
		
		if (nos.any { it.isEmpty })
			return this	// TODO: pod not found
		
		max := nos.map { it.size }
		cur := Int[,].fill(0, max.size)
		fin := false
		while (fin.not) {
			
			podLst := cur.map |v, i| { nos[i][v].dup }
			podMap := Str:PodNode[:].addList(podLst) { it.name }
			fin = reduceDomain(podMap)
			if (fin) {
				finNodes = podMap
				
				podLst = cur.map |v, i| { nos[i][v].dup }
				podMap = Str:PodNode[:].addList(podLst) { it.name }
				
				constraints := (PodConstraint[]) podMap.vals.map { it.toConstraints }.flatten
//				echo(constraints.toStr.replace(",", "\n"))
//				echo(finNodes.vals.sort.map { it.toPodFile } )
				fin = reduceDomain(podMap)
			}
			
			if (fin.not) {
				idx := cur.size - 1
				add := false
				while (add.not) {
					add = true
					cur[idx]++
					if (cur[idx] >= max[idx]) {
						add = false
						cur[idx] = 0
						idx--
						if (idx < 0) {
							add = true
							fin = true
						}
					}
				}			
			}
		}
		
		// TODO: we should filter out pods that can't be reached from the initPods - they could be left over depends from older versions

		podFiles = finNodes?.map { it.toPodFile }		
		return this
	}
	
	// see https://en.wikipedia.org/wiki/AC-3_algorithm
	Bool reduceDomain(Str:PodNode podNodes) {
		constraints := (PodConstraint[]) podNodes.vals.map { it.toConstraints }.flatten
		worklist	:= constraints.dup

		// TODO: create a cache list of known -> failures
		
		while (worklist.isEmpty.not) {
			arc := worklist.pop
			ver := podNodes[arc.depend.name].podVersion
			if (arcReduce(arc, podNodes)) {
				destNode := podNodes[arc.depend.name]
//				if (destNode.podVersions.isEmpty) {
				if (destNode.podVersion == null) {
//					availableVersions := destNode.podVersions.map { version }.join(", ")
//					causes := destNode.removalCauses.join(", ")
//					throw Err("Could not resolve ${destNode.name} ${availableVersions} due to ${causes}")
					echo("Can not satisfy '${arc}' with '${ver}'")
					return false
				}
				else {
					// worklist := worklist + { (z, x) | z != y and there exists a relation R2(x, z) or a relation R2(z, x) }
//					goBack := constraints.findAll { it.depend.name == arc.depend.name }
					goBack := constraints.findAll { it.depend.name == destNode.name }//???
					worklist.addAll(goBack)
				}
			}
		}
		return true
	}
	
	Bool arcReduce(PodConstraint arc, Str:PodNode podNodes) {
		change := false
		
		destNode := podNodes[arc.depend.name] ?: throw Err("Could not find pod ${arc.depend.name} in ${podNodes.keys}")
		dx := destNode.podVersion
		if (arc.depend.name == "afPegger" || arc.podNode.name == "afPegger") {
			echo("#### $arc ::: ${arc.depend} matches ${dx} => ${arc.depend.match(dx.version)}")
			echo("#### $destNode")
			echo("#### $arc.podVersion")
			echo
		}
//		destNode.podVersions.each |dx| {
			if (arc.depend.match(dx.version).not) {
				destNode.removeVersion(dx, arc)
				change = true
			}
//		}
		
		return change
	}
	
	
	// in the event multiple pods satisfy the dependencies, pick the latest ones
	Void pickLatestPods(Str:PodNode podNodes) {
		podNodes.each {
			echo(it.name + " : " + it.podVersions.map{version}.toStr)
		}
//		podNodes.each { it.pickLatestVersion }
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
}


class PodNode {
	const 	Str				name
			PodVersion?		podVersion
			PodVersion[]?	podVersions
//		PodConstraint[]		removalCauses	:= PodConstraint[,]

	new make(|This|in) { in(this) }

	This pickLatestVersion() {
		picked := podVersions.sort.last
		podVersions	= picked == null ? PodVersion#.emptyList : [picked]
		return this
	}
	
	This addPodVersions(PodVersion[] pods) {
		podVersions = (podVersions == null) ? pods : podVersions.addAll(pods).unique.sort.reverse	// highest first
		return this
	}
	
	Void removeVersion(PodVersion podVersion, PodConstraint cause) {
		if (this.podVersion != podVersion)
			throw Err("${this.podVersion} != ${podVersion}")
		this.podVersion = null
//		podVersions.remove(podVersion)
//		removalCauses.add(cause)
	}
	
	PodFile toPodFile() {
//		if (podVersions.isEmpty)
//			throw Err("No pod version found for ${name}")
//		if (podVersions.size > 1)
//			throw Err("Too many versions for ${name}")

		if (podVersion == null)
			throw Err("No pod version found for ${name}")
		return PodFile {
			it.name 	= this.name
			it.version	= this.podVersion.version
			it.file		= this.podVersion.file
		}
	}

	// permutate
	PodNode[] permutate() {
		podVersions.map |ver| {
			PodNode {
				it.name = this.name
				it.podVersion = ver
			}
		}
	}
	
	PodNode dup() {
		PodNode {
			it.name = this.name
			it.podVersion = this.podVersion
		}
	}
	
//	PodConstraint[] toConstraints() {
//		podVersions.map { it.toConstraints(this) }.flatten
//	}
	PodConstraint[] toConstraints() {
		podVersion.toConstraints(this)
	}

	override Str toStr() 			{ podVersion?.toStr ?: "${name} XXX" }
	override Int hash() 			{ name.hash }
	override Bool equals(Obj? that)	{ name == that?->name }
}

class PodVersion {
	const 	Str			name
	const 	Version		version
	const	Depend		depend
	const	File		file
	const	Depend[]	depends

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