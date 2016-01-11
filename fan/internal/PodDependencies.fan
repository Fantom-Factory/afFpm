
internal class PodDependencies {

			Str?				targetPod
			Str:PodFile			podFiles		:= Str:PodFile[:]

	internal PodResolvers		podResolvers
	internal Str?				building

	private PodConstraint[][]	allUnsatisfied	:= PodConstraint[][,]
	private FileCache			fileCache		:= FileCache()
	private PodNode[]			initNodes		:= PodNode[,]
	private Str:PodNode			allNodes		:= Str:PodNode[:] { it.ordered = true }

	new make(FpmConfig config, File[] podFiles) {
		this.podResolvers	= PodResolvers(config, podFiles, fileCache)
	}

	Void setBuildTarget(Str name, Version version, Depend[] depends, Bool checkDependencies) {
		addPod(name) {
			// check the build dependencies exist
			if (checkDependencies)
				depends.each {
					if (podResolvers.resolve(it).isEmpty)
						throw UnknownPodErr(ErrMsgs.env_couldNotResolvePod(it))
				}

			it.podVersions = [PodVersion(null, Str:Str[
				"pod.name"		: name,
				"pod.version"	: version.toStr,
				"pod.depends"	: depends.join(";")
			])]
		}
		targetPod	= "${name} ${version}"
		building	= name
	}
	
	Void setRunTarget(Depend podDepend) {
		podNode := addPod(podDepend.name) {
			it.podVersions = podResolvers.resolve(podDepend)
		}.pickLatestVersion
		
		if (podNode.podVersions.isEmpty)
			throw UnknownPodErr(ErrMsgs.env_couldNotResolvePod(podDepend))
		
		targetPod	= podDepend.toStr		
	}
	
	PodVersion[] availablePodVersions(Str podName) {
		allNodes[podName].podVersions
	}
	
	internal PodNode addPod(Str podName) {
		podNode := PodNode {
			it.name = podName
		}
		allNodes[podName] = podNode
		initNodes.add(podNode)
		return podNode
	}

	Bool isEmpty() {
		initNodes.isEmpty
	}
	
	This satisfyDependencies() {
		stack := Depend[,]
		allNodes.vals.each { expandNode(it, stack) }
		finNodes := ([Str:PodVersion]?) null

		// brute force - try every permutation of pod versions and see which ones work		
		nos := (PodVersion[][]) allNodes.vals.map { it.podVersions }

		max := nos.map { it.size }
		cur := Int[,].fill(0, max.size)
		err := (Str:PodVersion[]) allNodes.map { PodVersion[,] }
		fin := false
		while (fin.not) {
			podLst := cur.map |v, i| { nos[i].getSafe(v) }.exclude { it == null }
			podMap := Str:PodVersion[:].addList(podLst) { it.name }

			// filter out pods that can't be reached with current selection
			copyPod := (|Str:PodVersion, Str|?) null
			copyPod = |Str:PodVersion podVers, Str podName| {
				if (podVers.containsKey(podName)) return	// stack overflow
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

			// check cache of known failures
			if (podMap2.any |v, k| { err[k].contains(v) }.not) {
				res := reduceDomain(podMap2)
				if (res != null) {
					allUnsatisfied.add(res.unique)
					err[res.first.dependsOn.name].add(res.first.pVersion)

				} else {
					// found a working combination!
					finNodes = podMap2
					fin = true
				}
			}

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

		podFiles = finNodes?.exclude{ it.url == null }?.map { it.toPodFile } ?: Str:PodFile[:]
		if (podFiles.isEmpty.not)
			allUnsatisfied.clear
		return this
	}
	
	PodConstraint[] unsatisfied() {
		allUnsatisfied.min |c1, c2| { c1.size <=> c2.size } ?: PodConstraint#.emptyList
	}
	
	// see https://en.wikipedia.org/wiki/AC-3_algorithm
	private PodConstraint[]? reduceDomain(Str:PodVersion podVersions) {
		worklist := (PodConstraint[]) podVersions.vals.map { it.constraints }.flatten
		allCons	 := worklist.dup
		unsatisfied	:= null as PodConstraint[] 
		
		while (worklist.isEmpty.not) {
			con := worklist.pop
			nod := podVersions[con.dependsOn.name]
			if (nod == null || con.dependsOn.match(nod.version).not) {
				// find out who else conflicted / removed the versions we wanted
				all := allCons.findAll { it.dependsOn.name == con.dependsOn.name }.insert(0, con).unique
				if (unsatisfied == null)
					unsatisfied = PodConstraint[,]
				// collect ALL the errors, so we can report on the solution with the smallest number of errs (if need be)
				unsatisfied.addAll(all)
			}
		}

		return unsatisfied
	}
	
	private Void expandNode(PodNode node, Depend[] stack) {
		node.podVersions.each |podVersion| {
			if (stack.contains(podVersion.depend).not) {
				stack.add(podVersion.depend)			
				podVersion.depends.each |depend| {
					innerNode := resolveNode(depend)
					expandNode(innerNode, stack)
				}
			}
		}
	}

	private PodNode? resolveNode(Depend dependency) {
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
		picked := podVersions?.sort?.last
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
