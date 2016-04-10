
internal class PodDependencies {
	private const Log			log
			Str?				targetPod
			Str:PodFile			podFiles		:= Str:PodFile[:]

	internal PodResolvers		podResolvers
	internal Str?				building
	internal UnresolvedPod[]	unresolvedPods	:= UnresolvedPod#.emptyList 

	private FileCache			fileCache		:= FileCache()
	private PodNode[]			initNodes		:= PodNode[,]
	internal Str:PodNode		allNodes		:= Str:PodNode[:] { it.ordered = true }
	
	private	Duration			startTime		:= Duration.now

	new make(FpmConfig config, File[] podFiles, Log log) {
		this.log 			= log
		this.podResolvers	= PodResolvers(config, podFiles, fileCache)
	}

	Void setBuildTargetFromBuildPod(BuildPod buildPod, Bool checkDependencies) {
		podName	:= buildPod.podName 
		version	:= buildPod.version 
		depends	:= buildPod.depends 
		setBuildTarget(podName, version, depends.map { Depend(it, false) }.exclude { it == null }, checkDependencies)
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
		// TODO have some sort of trace / verbose flag where we show *everything*!
		if (targetPod == null)
			return this
		
		// turn off debug when we're analysing ourself!
		oldLogLevel := log.level
		if (targetPod != null && targetPod.startsWith("afFpm"))
			log.level = LogLevel.info
		
		log.debug("Resolving pods for $targetPod")

		allNodes.vals.each { expandNode(it, Depend[,]) }

		// there's an opportunity for podPerms to overflow here! (Scary!) 
		// but there's no Err, the number just wraps round to zero
		podPerms  := (Int) allNodes.vals.reduce(1) |Int tot, node| { tot * node.podVersions.size }
		totalVers := (Int) allNodes.vals.reduce(0) |Int tot, node| { tot + node.podVersions.size }
		log.debug("Found ${totalVers.toLocale} versions of ${allNodes.size.toLocale} different pod" + s(allNodes.size))
		
		// reduce PodVersions into groups
		// this reduces the problem space from 661,348,800,000 dependency permutations to just 12,288!		
		nos := (PodGroup[][]) allNodes.vals.map { it.reduceProblemSpace }.exclude { it->isEmpty }

		grpPerms	:= (Int) nos.reduce(1) |Int tot, vers| { tot * vers.size }
		podPermsStr	:= podPerms.toLocale
		grpPermsStr	:= grpPerms.toLocale
		maxPermSize	:= (podPermsStr.size + 11).max(grpPermsStr.size + 13)
		log.debug("Calculated "   + podPermsStr.justr(maxPermSize - 11) + " dependency pod permutation" + s(podPerms))
		log.debug("Collapsed to " + grpPermsStr.justr(maxPermSize - 13) + " dependency group permutation" + s(grpPerms))
		log.debug("Stated problem space in ${(Duration.now - startTime).toLocale}")
		log.debug("Solving...")
		startTime = Duration.now

		max := nos.map { it.size }
		cur := Int[,].fill(0, max.size)
		
		// a single err should be formed from multiple constraints, where A, B, C !==> D
//		err := (Str:PodVersion[]) allNodes.map { PodVersion[,] }
		fin := false
		solutions := [Str:PodFile][,]

		podMap  := Str:PodGroup[:] 
		
		
		unsatisfied	:= UnresolvedPod[,]
		badGroups	:= Int?[][,]

		// brute force - try every permutation of pod versions and see which ones work
		while (fin.not) {
			badIdx := badGroups.findIndex |badGrp->Bool| {
				cur.all |v, i->Bool| { val := badGrp[i]; return val == null || val == v }
			}

			if (badIdx == null) {
				podMap.clear
				cur.each |v, i| { grp := nos[i][v]; podMap[grp.name] = grp }
	
				res := reduceDomain(podMap)

				if (res != null) {
					depGrps := groupBy(res) |PodConstraint con->Str| { con.dependsOn.name }
					depGrps.each |PodConstraint[] naa| {
						names  := naa.map { it.pod.name }.add(naa.first.dependsOn.name)
						badGrp := cur.map |v, i->Int?| {
							names.contains(nos[i][v].name) ? v : null
						}
						badGroups.add(badGrp)
					}
					
					// keep the error with the least amount of unsatisfied constraints
					// ... actually, that isn't always the best error to report
//					if (unsatisfied.isEmpty || res.size < unsatisfied.size)
					
					badPods := logErr(res)
					if (unsatisfied.isEmpty && badPods != null)
						unsatisfied = badPods

				} else {
					// found a working combination!
	//				fin = true	// gotta find them all!
					solutions.add(
						podMap
							.map { it.latest }
							.exclude |PodVersion p->Bool| { p.url == null }
							.map |PodVersion p->PodFile| { p.toPodFile }
					)
				}
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
		log.debug("          ...Done")
		log.debug("Cached ${badGroups.size} bad dependency group" + s(badGroups.size))
		log.debug("Found ${solutions.size} solution${s(solutions.size)} in ${solveTime.toLocale}")
		

		// find the best solution -> the one with the greatest number of higher pod versions
		if (solutions.size > 0) {
			// rank all the pod versions
			podRanks := Str:Version[][:]
			solutions.each |solution| {
				solution.each |PodFile podFile, name| {
					podRanks.getOrAdd(name) { Version[,] }.add(podFile.version)
				}
			}
			podRanks.each { it.sortr }	// sort() sorts in place
			
			// score each solution according to the pod ranks
			solRanks := solutions.map |solution->Obj| {
				// we could normalise the rank index for each pod to 1 -> 10
				// but pfft - why bother complicate things further!?
				score := solution.reduce(0) |Int score, PodFile pod->Int| { score + podRanks[pod.name].index(pod.version) }
				return [score, solution]
			} as Obj[][]
			podFiles = solRanks.min |s1, s2->Int| { s1[0] <=> s2[0] }.last
		}
		
		// convert errors to UnresolvedPods
		if (solutions.isEmpty) {
			// now done in logErr()
//			conGrps := groupBy(unsatisfied) |PodConstraint con->Str| { con.dependsOn.name }
//			unresolvedPods = conGrps.map |PodConstraint[] cons, Str name->UnresolvedPod| {
//				UnresolvedPod {
//					it.name			= name
//					it.available	= availablePodVersions(name).map { it.version }
//					it.committee	= cons.sort
//				}
//			}.vals
			unresolvedPods = unsatisfied
		}
		
		log.level = oldLogLevel
		return this
	}
	
	private UnresolvedPod[]? logErr(PodConstraint[] unsat) {
		conGrps := groupBy(unsat) |PodConstraint con->Str| { con.dependsOn.name }
		unresolvedPods := (UnresolvedPod[]) conGrps.map |PodConstraint[] cons, Str name->UnresolvedPod| {
			UnresolvedPod {
				it.name			= name
				it.available	= availablePodVersions(name).map { it.version }
				it.committee	= cons.sort
			}
		}.vals

		// FIXME: dodgy pod constraints!
		dodgy := unresolvedPods.any { it.isDodgy }

		if (log.isDebug && !dodgy)
			log.debug("\n-----\n" + Utils.dumpUnresolved(unresolvedPods))
		
		return dodgy ? null : unresolvedPods
	}
	
	// see https://en.wikipedia.org/wiki/AC-3_algorithm
	private PodConstraint[]? reduceDomain(Str:PodGroup podGroups) {
		podGroups.each { it.reset }
		worklist := (PodConstraint[]) podGroups.reduce(PodConstraint[,]) |PodConstraint[] cons, grp->PodConstraint[]| { cons.addAll(grp.constraints) }
		allCons	 := worklist.dup
		unsatisfied	:= null as PodConstraint[] 

		while (worklist.isEmpty.not) {
			con := worklist.pop
			nod := podGroups[con.dependsOn.name]

			if (nod == null || nod.noMatch(con.dependsOn)) {
				// find out who else conflicted / removed the versions we wanted
				// collect ALL the errors, so we can report on the solution with the smallest number of errs (if need be)
				unsatisfied = allCons.findAll { it.dependsOn.name == con.dependsOn.name }
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
	
	private static Str s(Int size) {
		size == 1 ? "" : "s"
	}
	
	private static Obj:Obj[] groupBy(Obj[] list, |Obj item, Int index->Obj| keyFunc) {
		list.reduce(Obj:Obj[][:] { it.ordered = true}) |Obj:Obj[] bucketList, val, i| {
			key := keyFunc(val, i)
			bucketList.getOrAdd(key) { Obj[,] }.add(val)
			return bucketList
		}
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
