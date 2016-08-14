using util
using fanr::PodSpec

** Queries repositories for versions of a named pod.
** 
** The whole FPM environment is queried, including all local file and remote 
** fanr repositories. 
** 
** Examples:
** 
**   C:\> fpm query myPod
**   C:\> fpm query myPod 2.0+
** 
@NoDoc	// Fandoc is only saved for public classes
class QueryCmd : FpmCmd {

	@NoDoc @Opt { aliases=["n"]; help="Max number of pod versions to return from each repo" } 
	Int numVersions	:= 5
	
//	@Opt { aliases=["r"]; help="Name or location of a repository to query" }
//	Str? repo

	// TODO update, resolving ALL pods
//	@Opt { aliases=["a"]; help="By default FPM will only query for pods newer than the ones on your file system. This option will look for ALL pods, but at the expense of a much slower resolution." }
//	Str all	:= "all"

	@Arg { help="The pod whose dependencies are to be updated" }
	Str[]? pod

	new make() : super.make() { }

	override Int go() {
		pod := this.pod?.join(" ")
		printTitle("FPM: Querying for ${pod}")

		query := pod.replace("@", " ")
		if (query.contains(" ").not)
			query += " 0+"

		dependency	:= Depend(query)
		fileCache	:= FileCache()
		total		:= 0

		// list pods in precedence order
		
		fpmConfig.podDirs.each |podDir| {
			total += resolve("Pod Dir (${podDir.osPath})", PodResolverPath(podDir, fileCache), dependency)
		}
		
		fpmConfig.fileRepos.each |repoDir, name| {
			total += resolve("File Repo ${name} (${repoDir.osPath})", PodResolverFanrLocal(repoDir, fileCache), dependency)
		}
		
		fpmConfig.workDirs.each |workDir| {
			total += resolve("Work Dir (${workDir.osPath})", PodResolverPath(workDir, fileCache), dependency)
		}
		
		fpmConfig.fanrRepos.each |fanrUrl, repoName| {
			total += resolve("Fanr Repo ${repoName} (${fanrUrl})", PodResolverFanrRemote(fpmConfig, repoName, numVersions, null, true, null), dependency)
		}

		log.info("Found ${total} pods.")
		
		return 0
	}
	
	private Int resolve(Str type, PodResolver resolver, Depend dependency) {
		vers := resolver.resolve(dependency)
		if (vers.size > 0) {
			log.info(type)
			log.info(" - found ${dependency.name} " + vers.join(", ") { it.version.toStr })
			log.info("")
		}
		return vers.size
	}
	
	override Bool argsValid() {
		pod != null && pod.size > 0
	}
}
