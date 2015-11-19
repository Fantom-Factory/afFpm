
internal class PodDependencies {

	PodResolvers	podResolvers
	FileCache		fileCache		:= FileCache()
	PodNode[]		initNodes		:= PodNode[,]
	Str:PodNode		allNodes		:= Str:PodNode[:] { it.ordered = true }
	[Str:PodFile]?	podFiles

	new make(FpmConfig config, File[] podFiles) {
		this.podResolvers	= PodResolvers(config, podFiles, fileCache)
	}

	PodNode addPod(Depend dependency) {
		podNode := resolveNode(dependency)
		if (podNode.podVersions.isEmpty)
			throw Err("Could not find pod file for '${dependency}'")
		initNodes.add(podNode)
		return podNode
	}

	Bool isEmpty() {
		initNodes.isEmpty
	}
	
	This satisfyDependencies() {
		allNodes.vals.each { expandNode(it) }
		finNodes := ([Str:PodVersion]?) null

		// brute force - try every permutation of pod versions and see which ones work		
		nos := (PodVersion[][]) allNodes.vals.map { it.podVersions }

		max := nos.map { it.size }
		cur := Int[,].fill(0, max.size)
		fin := false
		while (fin.not) {
			podLst := cur.map |v, i| { nos[i].getSafe(v) }.exclude { it == null }
			podMap := Str:PodVersion[:].addList(podLst) { it.name }

			// filter out pods that can't be reached with current selection
			copyPod := (|Str:PodVersion, Str|?) null
			copyPod = |Str:PodVersion podVers, Str podName| {
				ver := podMap[podName]
				if (ver != null) {
					podVers[podName] = ver
					ver.depends.each {
						copyPod(podVers, it.name)
					}
				}
			}			
			podMap2 := Str:PodVersion[:]
			initNodes.each |initNode| { 
				copyPod(podMap2, initNode.name)
			}

			fin = reduceDomain(podMap2)
			if (fin)
				finNodes = podMap2

			// permutate through all versions of podsS
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

		podFiles = finNodes?.map { it.toPodFile }		
		return this
	}
	
	// see https://en.wikipedia.org/wiki/AC-3_algorithm
	Bool reduceDomain(Str:PodVersion podVersions) {
		worklist := (PodConstraint[]) podVersions.vals.map { it.constraints }.flatten

		// TODO: create a cache list of known -> failures
		
		while (worklist.isEmpty.not) {
			arc := worklist.pop
			nod := podVersions[arc.depend.name]
			if (nod == null || arc.depend.match(nod.version).not)
				return false
		}
		return true
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
		// TODO: cyclic redundency check
		allNodes.getOrAdd(dependency.name) {
			PodNode {
				it.name = dependency.name
			}
		}.addPodVersions(podResolvers.resolve(dependency))
	}	
}


internal class PodNode {
	const 	Str				name
			PodVersion[]?	podVersions

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
	
	override Str toStr() 			{ podVersions.first?.toStr ?: "${name} XXX" }
	override Int hash() 			{ name.hash }
	override Bool equals(Obj? that)	{ name == that?->name }
}

internal const class PodVersion {
	const 	Str				name
	const 	Version			version
	const	Depend			depend	// convenience for Depend("${name} ${version}")
	const	File			file
	const	Depend[]		depends
	const	PodConstraint[]	constraints

	new make(|This|in) {
		in(this)
		this.constraints = depends.map |d| { PodConstraint { it.podName = name; it.podVersion = this; it.depend = d } }		
	}

	new makeFromProps(File file, Str:Str metaProps) {
		this.file 		= file
		this.name		= metaProps["pod.name"]
		this.version	= Version(metaProps["pod.version"], true)
		this.depends	= metaProps["pod.depends"].split(';').map { Depend(it, false) }.exclude { it == null }
		this.depend		= Depend("${name} ${version}")
		this.constraints= depends.map |d| { PodConstraint { it.podName = name; it.podVersion = this; it.depend = d } }
	}
	
	PodFile toPodFile() {
		PodFile {
			it.name 	= this.name
			it.version	= this.version
			it.file		= this.file
		}
	}

	override Int compare(Obj that) {
		version <=> (that as PodVersion).version
	}

	override Str toStr() 			{ depend.toStr }
	override Int hash() 			{ depend.hash }
	override Bool equals(Obj? that)	{ depend == that?->depend }
}

internal const class PodConstraint {
	const Str			podName
	const PodVersion	podVersion
	const Depend		depend
	
	override Str toStr() {
		"${podName}@${podVersion.version} -> ${depend}"
	}
	
	new make(|This|in) { in(this) }
}