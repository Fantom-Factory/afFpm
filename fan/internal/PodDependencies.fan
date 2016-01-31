
internal class PodDependencies {
	private static const Log	log				:= PodDependencies#.pod.log
			Str?				targetPod
			Str:PodFile			podFiles		:= Str:PodFile[:]

	internal PodResolvers		podResolvers
	internal Str?				building

	private PodConstraint[][]	allUnsatisfied	:= PodConstraint[][,]
	private FileCache			fileCache		:= FileCache()
	private PodNode[]			initNodes		:= PodNode[,]
	internal Str:PodNode		allNodes		:= Str:PodNode[:] { it.ordered = true }
	
	private	Duration			startTime		:= Duration.now

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
		title := "Fantom Pod Manager ${typeof.pod.version}"
		log.debug(title)
		log.debug("".padl(title.size, '='))
		log.debug("Resolving pods for $targetPod")

		allNodes.vals.each { expandNode(it, Depend[,]) }

		podPerms  := (Int) allNodes.vals.reduce(1) |Int tot, node| { tot * node.podVersions.size }
		totalVers := (Int) allNodes.vals.reduce(0) |Int tot, node| { tot + node.podVersions.size }
		log.debug("Found ${totalVers.toLocale} versions of ${allNodes.size.toLocale} different pods")
		
		// reduce PodVersions into groups
		// this reduces the problem space from 661,348,800,000 dependency permutations to just 12,288!		
		nos := (PodGroup[][]) allNodes.vals.map { it.reduceProblemSpace }.exclude { it->isEmpty }

		grpPerms	:= (Int) nos.reduce(1) |Int tot, vers| { tot * vers.size }
		podPermsStr	:= podPerms.toLocale
		grpPermsStr	:= grpPerms.toLocale
		maxPermSize	:= (podPermsStr.size + 11).max(grpPermsStr.size + 13)
		log.debug("Calculated "   + podPermsStr.justr(maxPermSize - 11) + " dependency permutations")
		log.debug("Collapsed to " + grpPermsStr.justr(maxPermSize - 13) + " dependency permutations")
		log.debug("Problem space stated in ${(Duration.now - startTime).toLocale}")
		log.debug("Solving...")
		startTime = Duration.now

		max := nos.map { it.size }
		cur := Int[,].fill(0, max.size)
		
		// a single err should be formed from multiple constraints, where A, B, C !==> D
//		err := (Str:PodVersion[]) allNodes.map { PodVersion[,] }
		fin := false
		solutions := [Str:PodFile][,]

		podMap  := Str:PodGroup[:]

		// brute force - try every permutation of pod versions and see which ones work
		while (fin.not) {
			podMap.clear
			cur.each |v, i| { grp := nos[i][v]; podMap[grp.name] = grp }

			res := reduceDomain(podMap)

			if (res != null) {
//				allUnsatisfied.add(res.unique)	// FIXME 2 secs here!

			} else {
				// found a working combination!
//				fin = true
				solutions.add(podMap
					.map { it.latest }
					.exclude |PodVersion p->Bool| { p.url == null }
					.map |PodVersion p->PodFile| { p.toPodFile }
				)
			}

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

		solveTime := Duration.now - startTime
		log.debug("Found ${solutions.size} solutions in ${solveTime.toLocale}")

		podFiles = solutions.first ?: Str:PodFile[:]

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
		worklist := (PodConstraint[]) podGroups.reduce(PodConstraint[,]) |PodConstraint[] cons, grp->PodConstraint[]| { cons.addAll(grp.constraints) }
//		allCons	 := worklist.dup
		unsatisfied	:= null as PodConstraint[] 

		while (worklist.isEmpty.not) {
			con := worklist.pop
			nod := podGroups[con.dependsOn.name]

			if (nod == null || nod.noMatch(con.dependsOn)) {
//				// find out who else conflicted / removed the versions we wanted
//				all := allCons.findAll { it.dependsOn.name == con.dependsOn.name }.insert(0, con).unique
//				if (unsatisfied == null)
//					unsatisfied = PodConstraint[,]
//				// collect ALL the errors, so we can report on the solution with the smallest number of errs (if need be)
//				unsatisfied.addAll(all)
				
				unsatisfied = PodConstraint#.emptyList
				worklist.clear
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
				group.add(pod)
		}
		return groups.vals
	}
	
	override Str toStr() 			{ podVersions?.first?.toStr ?: "${name} XXX" }
	override Int hash() 			{ name.hash }
	override Bool equals(Obj? that)	{ name == that?->name }
}
