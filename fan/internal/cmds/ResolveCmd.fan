
** Resolves dependencies for the given pod. Useful for testing the current environment.
** 
** Examples:
** 
**   C:\> fpm resolve myPod
**   C:\> fpm resolve myPod/2.0
** 
@NoDoc	// Fandoc is only saved for public classes
class ResolveCmd : FpmCmd {

	@Arg { help="The pod to query for" }
	Depend?	target

	new make(|This| f) : super(f) { }

	override Int run() {

		Repository[] repos := Repository[,]
		repos.addAll(fpmConfig.repositories)
		
		if (target == null) {
			// look at our current context to try to determine target
			File buildFile := File(`build.fan`) // relative to working dir
			if(!buildFile.exists()) {
				log.warn("Resolve what!?")
				return invalidArgs
			}
			
			// we assume the described pod is built and latest version, we do not rebuild
			File buildDir := File(`build/`);
			File[] pods := buildDir.listFiles(Regex.glob("*.pod"))
			if(!buildDir.exists || pods.isEmpty) {
				log.warn("Resolve what!?")
				return invalidArgs
			}
			
			spr := SinglePodRepository(pods.first)	
			target = spr.podFile.depend
			
			// insert at 0 so we always find this single pod repo first (and thus take its dependencies, rather than potentially outdated ones in another local repo)
			repos.insert(0, spr)
		} 

		resolver := Resolver(repos)
		resolver.log = log
		resolver.localOnly
		
		target := parseTarget(this.target.toStr)
		
		Satisfied? satisfied := null
		
		try {
			// TODO currently resolving target/someVer sometimes resolves the latest version regardless
			satisfied = resolver.satisfyPod(target, fpmConfig.extraPods)
		} catch(UnknownPodErr e) {
			log.warn("Could not find target '${target}'")
			return invalidArgs
		}

		if (satisfied.resolvedPods.isEmpty && satisfied.unresolvedPods.size > 0) {
			log.warn(FpmUtils.dumpUnresolved(satisfied.unresolvedPods.vals))
			return 9 // ?
		}

		podFiles := satisfied.resolvedPods.rw
		
		mainPod := podFiles.remove(target.name)
		buckets := podFiles.vals.groupBy { it.repository.name }
		
		log.info("resolved ${podFiles.size} pods")
		log.info("${mainPod?.depend ?: target.name}  ->  ${mainPod?.repository?.name}\n")
		
		buckets.each |PodFile[] pods, repoName| {
			log.info("${repoName} ->")
			max := pods.max |p1, p2| { p1.name.size <=> p2.name.size }.name.size
			pods.sort |p1, p2| { p1.name <=> p2.name }
			pods.each {
				log.info("  " + it.name.justl(max) + " " + it.depend.version)
			}
			log.info("")
		}
		
		return 0
	}

}
