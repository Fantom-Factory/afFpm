
internal class PodDependencies {

			Str?				targetPod
			Str:PodFile			podFiles		:= Str:PodFile[:]

	internal PodResolvers		podResolvers
	internal Str?				building

	private PodConstraint[][]	allUnsatisfied	:= PodConstraint[][,]
	private FileCache			fileCache		:= FileCache()
	private PodNode[]			initNodes		:= PodNode[,]
	internal Str:PodNode		allNodes		:= Str:PodNode[:] { it.ordered = true }

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
//		echo("####")
//		Buf().writeObj(allNodes).flip.readAllStr.with { echo(it) }
//		echo("#### -")
		
		stack := Depend[,]
		allNodes.vals.each { expandNode(it, stack) }
		finNodes := ([Str:PodGroup]?) null

		// reduce PodVersions into groups
		// this reduces the problem space from 661,348,800,000 dependency permatations to just XXX
		
		
		
		// brute force - try every permutation of pod versions and see which ones work
		nos := (PodGroup[][]) allNodes.vals.map { it.reduceProblemSpace }
		max := nos.map { it.size }
		cur := Int[,].fill(0, max.size)
//		err := (Str:PodGroup[]) allNodes.map { PodGroup[,] }
		fin := false
		
		pems := (Int) nos.reduce(1) |Int tot, vers| { tot * vers.size }
		echo("Solving ${pems.toLocale} dependency permatations")
		nos.each |groups| {
			pods := groups.join(", ", |p->Str| { p.podVersions.keys.join(", ") { it.version.toStr } })
			echo("${groups.size} x ${groups.first?.name} : $pods") 
		}
		pem:=0

		while (fin.not) {
			pem++
			podLst := cur.map |v, i| { nos[i].getSafe(v) }.exclude { it == null }
			podMap := Str:PodGroup[:].addList(podLst) { it.name }

			// filter out pods that can't be reached with current selection
			copyPod := (|Str:PodGroup, Str|?) null
			copyPod = |Str:PodGroup podVers, Str podName| {
				if (podVers.containsKey(podName)) return	// stack overflow
				ver := podMap[podName]
				if (ver != null) {
					podVers[podName] = ver
					ver.depends.each {
						copyPod(podVers, it.name)
					}
				}
			}
			podMap2 := Str:PodGroup[:]
			initNodes.each |initNode| { 
				copyPod(podMap2, initNode.name)
			}

//			echo("Solving $podMap2")
//			echo("    --> ${reduceDomain(podMap2)}")
	
			// check cache of known failures
//			if (podMap2.any |v, k| { err[k].contains(v) }.not) {
				res := reduceDomain(podMap2)
				if (res != null) {
					allUnsatisfied.add(res.unique)
//					err[res.first.dependsOn.name].add(res.first.pVersion)

				} else {
					// found a working combination!
					finNodes = podMap2
					fin = true
				}
//			}

			// permutate through all versions of pods
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

		echo("Solved after ${pem.toLocale} permatations")
		echo(finNodes)

		podFiles = finNodes
			?.map { it.latest }
			?.exclude |PodVersion p->Bool| { p.url == null }
			?.map |PodVersion p->PodFile| { p.toPodFile }
			?: Str:PodFile[:]

		if (podFiles.isEmpty.not)
			allUnsatisfied.clear
		
		return this
	}
	
	UnresolvedPod[] unsatisfied() {
		(allUnsatisfied.min |c1, c2| { c1.size <=> c2.size } ?: PodConstraint#.emptyList).map |PodConstraint con->UnresolvedPod| { UnresolvedPod {
			it.name			= con.podName
			it.version		= con.podVersion
			it.dependsOn	= con.dependsOn
			it.available	= availablePodVersions(it.dependsOn.name).map { it.version }
		} }
	}
	
	// see https://en.wikipedia.org/wiki/AC-3_algorithm
	private PodConstraint[]? reduceDomain(Str:PodGroup podGroups) {
		podGroups.each { it.reset }
		worklist := (PodConstraint[]) podGroups.vals.map { it.constraints }.flatten
		allCons	 := worklist.dup
		unsatisfied	:= null as PodConstraint[] 
		
		while (worklist.isEmpty.not) {
			con := worklist.pop
			nod := podGroups[con.dependsOn.name]

			// FIXME clone pod groups / set Bool markers?
			// FIXME tidty
			if (nod != null) {
				nod.select(con.dependsOn)
//				nod.podVersions = nod.podVersions.findAll { con.dependsOn.match(it.version) }
			}
			
			// FIXME: versions ANY?? does that mean I need check which final version to use?
//			if (nod == null || nod.versions.any { con.dependsOn.match(it) }.not) {
			if (nod == null || nod.podVersions.all { it == false}) {
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
		node.podVersions?.each |podVersion| {
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


@Serializable
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
	
	PodGroup[] reduceProblemSpace() {
		groups := Str:PodGroup[:]
		podVersions.each |pod| {
			group := groups[pod.dependsHash]
			if (group == null)
				groups[pod.dependsHash] = PodGroup(pod)
			else
				group.podVersions[pod] = true
		}
		return groups.vals
	}
	
	override Str toStr() 			{ podVersions?.first?.toStr ?: "${name} XXX" }
	override Int hash() 			{ name.hash }
	override Bool equals(Obj? that)	{ name == that?->name }
}
