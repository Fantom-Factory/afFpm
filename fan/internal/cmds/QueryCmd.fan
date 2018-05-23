
** Queries repositories for pods.
** 
** The whole FPM environment is queried, including all local file and remote 
** fanr repositories. 
** 
** Examples:
** 
**   C:\> fpm query myPod
**   C:\> fpm query myPod@2.0+
**   C:\> fpm query "myPod 2.0+"
** 
@NoDoc	// Fandoc is only saved for public classes
class QueryCmd : FpmCmd {

	@NoDoc @Opt { aliases=["n"]; help="Max number of pod versions to return from each repo" } 
	Int numVersions	:= 5
	
	@Opt { aliases=["r"]; help="Name or location of a specific repository to query" }
	Repository? repo

	@Opt { aliases=["o"]; help="If specified, then only local repositories will be queried" }
	Bool offline

	@Arg { help="The pod to query for" }
	Depend	target

	new make(|This| f) : super(f) { }

	override Int run() {
		log.info("FPM querying for ${target}")
		if (offline)
			log.info("<FPM offline mode>")

		repos	:= repo == null ? fpmConfig.repositories.unique : [repo]
		if (offline)
			repos = repos.findAll { it.isLocal }
		
		if (repos.isEmpty) {
			log.err("No repositories to query")
			return invalidArgs
		}
		
		opts	:= [:]
		total	:= 0
		repos.each |repo| {
			pods := repo.resolve(target, opts)
			if (pods.size > 0) {
				log.info("\n${repo.name} (${repo.url})")
				log.info(" - found ${target.name} " + pods.join(", ") { it.depend.version.toStr })
			}
			total += pods.size
		}

		log.info("\nFound ${total} pods.")
		return 0
	}
}
