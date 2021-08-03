
** This is where the real stuff happens!
** The implementation is a bit naive and has room for improvement - but seems work well.
** 
** Note also, that this is a very small part of FPM! The Environment, Repositories, and Cmds all 
** play a huge part and deflect my time away from this little class / problem.
internal class Satisfier {
	private static const Int	MAX_BAD_GROUPS	:= 500
			Log					log				:= typeof.pod.log
			Bool				writeTraceFile	:= false
			Duration			resolveTimeout1	:= 5sec
			Duration			resolveTimeout2	:= 10sec

			Bool				building
			Depend				targetPod
			Depend[]			targetDependsOn
			Str:PodFile			resolvedPods	:= Str:PodFile[:]
			Str:UnresolvedPod	unresolvedPods	:= Str:UnresolvedPod[:]
	
	// the order shouldn't be an issue, but the order of the resulting PodGroups does have a HUGE effect on the resolve time 
	// and can shave WHOLE SECONDS off!
//	private Str:PodNode			podNodes		:= Str:PodNode[:] { it.ordered = true }
	private Str:PodNode			podNodes		:= Str:PodNode[:]
	private	Duration			startTime		:= Duration.now
	private	Resolver			resolver

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
			
			building = true
		}
		
		// to save us the hassle of resolving and de-ciphering the UnresolvedPod results 
		// just make sure we have the direct dependencies first
		initNode.podVersions.first.dependsOn.each {
			resolveNode(it, true)
		}
		
		podNodes[initNode.name] = initNode
		
		targetDependsOn = initNode.podVersions.first.dependsOn
	}
	
	This satisfyDependencies() {
		// todo have some sort of trace / verbose flag where we show *everything*!
		
		log.debug("Resolving pods for $targetPod")

		podNodes.vals.each { expandNode(it, Depend[,]) }
		
		// remove all pods that don't explicitly fit the defined dependencies
		// this can delete a *lot* of pods and leaves the satisfier to just clean up the transitive dependencies
		// this also removes user expletives such as "Where did that #@?$&# dependency come from!?"  
		numPodsB4 := (Int) podNodes.vals.reduce(0) |Int tot, pod| { tot + pod.size  }
		targetDependsOn.each |coreDepend| {
			podNodes[coreDepend.name].reduceCore(coreDepend)
		}
		numPodsA5 := (Int) podNodes.vals.reduce(0) |Int tot, pod| { tot + pod.size  }
		if (numPodsB4 != numPodsA5)
			log.debug("Removed ${numPodsB4 - numPodsA5} pods that were outside of the explicit dependencies")

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
		
		fin := false
		solutions	:= [Str:PodFile][,]
		podMap 		:= Str:PodGroup[:] 
		unsatisfied	:= UnresolvedPod[,]
		badGroups	:= Int?[][,]
		allBadPods	:= UnresolvedPod[][,]

		// fn caches
		pgrp 		:= null as PodGroup
		resetFn 	:= |Int v, Int i| { pgrp = nos[i][v]; podMap[pgrp.name] = pgrp }
		badIdxFn	:= |Int?[] badGrp -> Bool| {
			all := true
			i   := 0
			while (all && i < cur.size) {
				v   := cur[i]
				val := badGrp[i++]
				all = val == null || v == val
			}
			return all
			// this is what the above does
//			cur.all |v, i->Bool| { val := badGrp[i]; return val == null || val == v }
		}

		// brute force - try every permutation of pod versions and see which ones work
		count 	:= 0
		collect := true
		while (fin.not) {
			count++

			// note I deleted the badPodGroups optimisation - it worked, but it added extra SECONDS to calculate!
			// actually - double check, I think with ~400 cached groups, it saved 1 second!
			// Confusingly - this also reduced a 19 sec problem to 3 secs!
			badIdx := badGroups.findIndex(badIdxFn)
			if (badIdx == null) {

				podMap.clear
				cur.each(resetFn)
				collect = unsatisfied.isEmpty || badGroups.size < MAX_BAD_GROUPS
				res 	:= reduceDomain(podMap, collect)
	
				if (res != null) {

					// limit the number of bad groups - cos they become counter effective
					if (badGroups.size < MAX_BAD_GROUPS) {
						// TODO optimise fn
						depGrps := groupBy(res) |PodConstraint con->Str| { con.dependsOn.name }
						depGrps.each |PodConstraint[] naa| {
							// TODO optimise fn
							names  := naa.map { it.pod.name }.add(naa.first.dependsOn.name)
							// TODO optimise fn
							badGrp := cur.map |v, i->Int?| {
								names.contains(nos[i][v].name) ? v : null
							}
							badGroups.add(badGrp)
						}
					}
	
					// this will dump out ALL the bad dependencies
					if (log.isDebug)
						allBadPods.add(logErr(res, podMap)).unique
					
					// just take the first err as it should be the most relevant with the most number of latest versions 
					if (unsatisfied.isEmpty) {
						badPods := logErr(res, podMap)
						if (badPods != null)
							unsatisfied = badPods
					}
	
				} else {					
					// TODO optimise fn
					solutions.add(
						podMap.map { it.latest }.exclude { it == null }
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
				per   := 100f * count / grpPerms
				left  := (resolveTime * 100f / per) - resolveTime
				if (left > 1sec) {	// give it a 1sec grace to finish
					stats := "Churned through ${per.toLocale}% of problem space in ${resolveTime.toLocale}; ${left.toLocale} left"
					fin = true
					log.warn("Exceeded resolve timeout of ${resolveTimeout1.toLocale}. Returning early, resolved pods may be sub-optimal.\n${stats}\nTo increase timeout set environment variable FPM_RESOLVE_TIMEOUT_1 to a valid Fantom duration, e.g. 5sec")
				}
			}
			if (resolveTime > resolveTimeout2) {
				per   := 100f * count / grpPerms
				left  := (resolveTime * 100f / per) - resolveTime
				if (left > 1sec) {	// give it a 1sec grace to finish
					stats := "Churned through ${per.toLocale}% of problem space in ${resolveTime.toLocale}; ${left.toLocale} left"
					fin = true
					log.err("Could not find solution within ${resolveTimeout2.toLocale}. Returning early.\n${stats}\nTo increase timeout set environment variable FPM_RESOLVE_TIMEOUT_2 to a valid Fantom duration, e.g. 10sec")
				}
			}
		}

		solveTime := Duration.now - startTime
		log.debug("          ...Done")
		log.debug("Cached ${badGroups.size} " + (badGroups.size >= MAX_BAD_GROUPS ? "(MAX) " : "") + "bad dependency group" + s(badGroups.size))
		log.debug("Found ${solutions.size} solution${s(solutions.size)} in ${solveTime.toLocale}")
		
		
		if (solutions.size == 0 && log.isDebug) {
			allBadPods.each {
				log.debug( FpmUtils.dumpUnresolved(it) )
			}
		}

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
		
		if (building)
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
		out.printLine("satisfyDependencies(${targetPod.toStr.toCode})")

		out.flush.close
		log.debug("Wrote dependency trace file: $file.normalize.osPath")
	}
	
	private UnresolvedPod[]? logErr(PodConstraint[] unsat, Str:PodGroup podGroups) {
		conGrps := groupBy(unsat) |PodConstraint con->Str| { con.dependsOn.name }
		unresolvedPods := (UnresolvedPod[]) conGrps.map |PodConstraint[] cons, Str name->UnresolvedPod| {
			UnresolvedPod {
				it.name			= name
				it.available	= podGroups[name]?.versions ?: Version#.emptyList
				it.committee	= cons.sort
			}
		}.vals

		return unresolvedPods

//		// todo dodgy pod constraints!?
//		dodgy := unresolvedPods.all { it.isDodgy }
//		if (log.isDebug && dodgy)
//			log.debug("\n---- Dodgy Constraint ----\n" + Utils.dumpUnresolved(unresolvedPods))
//		
//		return dodgy ? null : unresolvedPods
	}

//	private PodFile[] allAvailablePodVersions(Str podName) {
//		podNodes[podName].podVersions
//	}

	// see https://en.wikipedia.org/wiki/AC-3_algorithm
	private PodConstraint[]? reduceDomain(Str:PodGroup podGroups, Bool collect) {
		
		// remove orphaned dependencies; just because a pod is in the grand main list, doesn't mean it is a dependency in of these specific versions - see TestSkySparkBug
		// TODO optimise fn
		podGroups = podGroups.findAll |podVal| {
			podVal.name == this.targetPod.name ||
			// TODO optimise fn
			podGroups.any { it.dependsOn.any { it.name == podVal.name } }
		}
		
		podGroups.each(resetFn)
		worklist := (PodConstraint[]) podGroups.reduce(PodConstraint[,], cacheFn)
		allCons	 := worklist.dup
		unsatisfied	:= null as PodConstraint[] 

		while (worklist.size > 0) {
			con := worklist.pop
			nod := podGroups[con.dependsOn.name]

			if (nod == null || !nod.matches(con.dependsOn)) {
				// TODO optimise fn
				// find out who else conflicted / removed the versions we wanted
				// collect ALL the errors, so we can report on the solution with the smallest number of errs (if need be)
				unsatisfied = collect ? allCons.findAll { it.dependsOn.name == con.dependsOn.name } : PodConstraint#.emptyList
				worklist.clear
			}
		}

		return unsatisfied
	}
	private static const |PodGroup podGroup| resetFn := |PodGroup podGroup| { podGroup.reset }
	private static const |PodConstraint[] cons, PodGroup grp->PodConstraint[]| cacheFn := |PodConstraint[] cons, PodGroup grp->PodConstraint[]| { cons.addAll(grp.constraints) }
	
	private Void expandNode(PodNode node, Depend[] stack) {
		node.podVersions?.each |podVersion| {
			if (stack.contains(podVersion.depend).not) {
				stack.add(podVersion.depend)			
				
				podVersion.dependsOn.each |depend| {
					innerNode := resolveNode(depend, false)
					
					// make sure we're NOT adding dependencies that our Target pod doesn't want (keep things streamlined)
					targetDepOn := targetDependsOn.find { it.name == innerNode.name }
					if (targetDepOn != null)
						innerNode.reduceCore(targetDepOn)
					
					expandNode(innerNode, stack)
				}
			}
		}
	}

	private PodNode resolveNode(Depend pod, Bool checked) {
		vers := resolver.resolve(pod)
		if (checked && vers.isEmpty)
			throw UnknownPodErr("Could not resolve pod: ${pod}")

		// TODO optimise fn
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
	
	Void reduceCore(Depend deps) {
		podVersions = podVersions.findAll |podVer| {
			deps.match(podVer.depend.version)
		}
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
	
	override Str toStr() 			{
		vers := podVersions?.join(",") { it.version.toStr } ?: "---"
		return "${name} ${vers}"
	}
	override Int hash() 			{ name.hash }
	override Bool equals(Obj? that)	{ name == that?->name }
}
