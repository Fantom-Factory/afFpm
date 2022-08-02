
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
		if (target == null) {
			log.warn("Resolve what!?")
			return invalidArgs
		}
		
		resolver := Resolver(fpmConfig.repositories)
		resolver.log		= log
		resolver.localOnly
		
		target := parseTarget(this.target.toStr)
		
		satisfied := resolver.satisfyPod(target)
		if (satisfied.resolvedPods.isEmpty && satisfied.unresolvedPods.size > 0) {
			log.warn(FpmUtils.dumpUnresolved(satisfied.unresolvedPods.vals))
			return 9
		}

		podFiles := satisfied.resolvedPods
		
		podFiles.each |pf| {
			log.info("${pf.depend}  ->  ${pf.repository.name}" )
		}
		return 0
	}
}
