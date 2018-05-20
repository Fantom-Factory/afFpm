
** This is where the real stuff happens!
** The implementation is a bit naive and has room for improvement - but seems work well.
** 
** Note also, that this is a very small part of FPM! The Environment, Repositories, and Cmds all 
** play a huge part and deflect my time away from this little class / problem.
internal class Satisfier {
			Log					log				:= typeof.pod.log
			Bool				writeTraceFile	:= false
			Duration			resolveTimeout1	:= 5sec
			Duration			resolveTimeout2	:= 10sec

			Depend				targetPod
			Str:PodFile			resolvedPods	:= Str:PodFile[:]
			Str:UnresolvedPod	unresolvedPods	:= Str:UnresolvedPod[:]
	
	private	Resolver			resolver
	private Str:PodNode			podNodes		:= Str:PodNode[:] { it.ordered = true }
	private	Duration			startTime		:= Duration.now

	new make(TargetPod target, Resolver	resolver, |This|? f := null) {
		f?.call(this)
		this.targetPod	= target.pod
		this.resolver	= resolver
		
		initNode := PodNode {
			it.name		= target.pod.name
			it.initNode = true
		}
		
		if (target.dependencies == null) {
			podVers := resolver.resolve(targetPod)
			if (podVers.isEmpty)
				throw UnknownPodErr("Could not resolve target: $targetPod")
			
			initNode.addPodVersions(podVers)
			// resolve should have returned the exact version, but just in case...
			initNode.pickLatestVersion
			
		} else {
			// we can't resolve buildPods 'cos the pod ain't built yet!
			// so set the given dependencies explicitly
			initNode.addPodVersions([target.podFile])
		}
		
		// to save us the hassle of resolving and de-ciphering the UnresolvedPod results 
		// just make sure we have the direct dependencies first
		initNode.podVersions.first.dependsOn.each {
			resolveNode(it, true)
		}
		
		podNodes[initNode.name] = initNode
	}
	
	This satisfyDependencies() {
		// todo have some sort of trace / verbose flag where we show *everything*!
		
		log.debug("Resolving pods for $targetPod")

		podNodes.vals.each { expandNode(it, Depend[,]) }

		// there's an opportunity for podPerms to overflow here! (Scary @ 9,223,372,036,854,775,807!) 
		// but there's no Err, the number just wraps round to zero
		podPerms  := (Int) podNodes.vals.reduce(1) |Int tot, node| { tot * node.size }
		totalVers := (Int) podNodes.vals.reduce(0) |Int tot, node| { tot + node.size }
		log.debug("Found ${totalVers.toLocale} versions of ${podNodes.size.toLocale} different pod" + s(podNodes.size))
		
		// reduce PodVersions into groups
		// this can reduce the problem space from 610,397,977,600 dependency permutations to just 138,240!		
		nos := (PodGroup[][]) podNodes.vals.map { it.reduceProblemSpace }.exclude { it->isEmpty }

		grpPerms	:= (Int) nos.reduce(1) |Int tot, vers| { tot * vers.size }
		podPermsStr	:= podPerms.toLocale
		grpPermsStr	:= grpPerms.toLocale
		maxPermSize	:= (podPermsStr.size + 11).max(grpPermsStr.size + 13)
		log.debug("Calculated "   + podPermsStr.justr(maxPermSize - 11) + " dependency pod permutation" + s(podPerms))
		log.debug("Collapsed to " + grpPermsStr.justr(maxPermSize - 13) + " dependency group permutation" + s(grpPerms))
		log.debug("Stated problem space in ${(Duration.now - startTime).toLocale}")
		log.debug("Solving...")
		
		if (writeTraceFile)
			doWriteTraceFile
		
		startTime = Duration.now
		max := nos.map { it.size }
		cur := Int[,].fill(0, max.size)
		
		// a single err should be formed from multiple constraints, where A, B, C !==> D
//		err := (Str:PodVersion[]) allNodes.map { PodVersion[,] }
		fin := false
		solutions	:= [Str:PodFile][,]
		podMap 		:= Str:PodGroup[:] 
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
					solutions.add(
						podMap.map { it.latest }
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
			
			// found a working combination!
			// use first solution if resolving takes over X seconds 
			resolveTime := Duration.now - startTime
			if (resolveTime > resolveTimeout1 && solutions.size > 0) {
				fin = true
				log.warn("Exceeded resolve timeout of ${resolveTimeout1.toLocale}. Returning early, resolved pods may be sub-optimal.\nTo increase timeout set environment variable FPM_RESOLVE_TIMEOUT_1 to a valid Fantom duration, e.g. 5sec")
			}
			if (resolveTime > resolveTimeout2) {
				fin = true
				log.err("Could not find solution within ${resolveTimeout2.toLocale}. Returning early.\nTo increase timeout set environment variable FPM_RESOLVE_TIMEOUT_2 to a valid Fantom duration, e.g. 10sec")
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
				score := solution.reduce(0) |Int score, PodFile pod->Int| {
					score + podRanks[pod.name].index(pod.version)
				}
				return [score, solution]
			} as Obj[][]
			resolvedPods = solRanks.min |s1, s2->Int| { s1[0] <=> s2[0] }.last
		}
		
		// convert errors to UnresolvedPods
		if (solutions.isEmpty) {
			unsatisfied.each { unresolvedPods[it.name] = it }
		}
		
		resolvedPods.remove(targetPod.name)
		return this
	}
	
	private Void doWriteTraceFile() {
		file	:= `fpm-trace-deps.txt`.toFile
		out  	:= file.out
		allPods := (PodFile[]) podNodes.vals.map { it.podVersions }.flatten.sort

		out.printLine("// Trace dependency file for $targetPod - ${DateTime.now.toLocale}")
		out.printLine
		allPods.each |pod| {
			out.printLine("addDep(${pod.depend.toStr.toCode}, " + pod.dependsOn.join(", ").toCode + ")")
		}
		out.printLine("satisfyDependencies(${targetPod})")

		out.flush.close
		log.debug("Wrote dependency trace file: $file.normalize.osPath")
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

		// todo dodgy pod constraints!?
		dodgy := unresolvedPods.any { it.isDodgy }
		if (log.isDebug && !dodgy)
			log.debug("\n-----\n" + Utils.dumpUnresolved(unresolvedPods))
		
		return dodgy ? null : unresolvedPods
	}

	private PodFile[] availablePodVersions(Str podName) {
		podNodes[podName].podVersions
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
				podVersion.dependsOn.each |depend| {
					innerNode := resolveNode(depend, false)
					expandNode(innerNode, stack)
				}
			}
		}
	}

	private PodNode resolveNode(Depend pod, Bool checked) {
		vers := resolver.resolve(pod)
		if (checked && vers.isEmpty)
			throw UnknownPodErr("Could not resolve pod: ${pod}")

		return podNodes.getOrAdd(pod.name) {
			PodNode { it.name = pod.name }
		}.addPodVersions(vers)
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
	const 	Str			name
	const	Bool		initNode
			PodFile[]?	podVersions { private set }

	new make(|This|in) { in(this) }

	This pickLatestVersion() {
		picked := podVersions?.sort?.last
		podVersions	= picked == null ? PodFile#.emptyList : [picked]
		return this
	}
	
	This addPodVersions(PodFile[] pods) {
		if (podVersions == null)
			podVersions = pods
		else {
			pods.each |pod| {
				// don't use contains() or compare the URL, because the same version pod may come from different sources
				// and we only need the one!
				existing := podVersions.find { it.fits(pod.depend) }
				if (existing == null)
					podVersions.add(pod)
				else {
					// replace remote pods with local versions
					if (existing.repository.isRemote && pod.repository.isLocal) {
						idx := podVersions.index(existing)
						podVersions[idx] = pod
					}
				}
			}
			
		}
		podVersions.sortr
		return this
	}
	
	PodGroup[] reduceProblemSpace() {
		groups := Str:PodGroup[:]
		podVersions.each |pod| {
			hash  := pod.dependsOn.dup.rw.sort.join("; ")
			group := groups[hash]
			if (group == null)
				groups[hash] = PodGroup(pod)
			else
				group.add(pod)
		}
		return groups.vals
	}
	
	Bool isEmpty() { podVersions.isEmpty }
	Int size() { podVersions.size }
	
	override Str toStr() 			{ podVersions?.first?.toStr ?: "${name} XXX" }
	override Int hash() 			{ name.hash }
	override Bool equals(Obj? that)	{ name == that?->name }
}
