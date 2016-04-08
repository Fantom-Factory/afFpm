using util
using fanr

** Installs a pod to a repository.
** 
** The repository may be:
**  - a named local repository (e.g. 'default')
**  - a named remote repository (e.g. 'fantomFactory')
**  - the directory of a local repository (e.g. 'C:\repo-release\')
**  - the URL of a remote repository (e.g. 'http://pods.fantomfactory.org/fanr/')
** 
** The pod may be:
**  - a file location, absolute or relative. Example, 'lib/myAweseomeGame.pod'
**  - a simple search query. Example, '"afIoc 3.0"' or 'afIoc@3.0'
** 
** All the above makes the 'install' command very versatile. Some examples:
** 
** To download and install the latest pod from a remote repository:
** 
**   C:\> fpm install myPod
** 
** To download and install a specific pod version to a local repository:
** 
**   C:\> fpm install -r release myPod 2.0.10
** 
** To upload and publish a pod to the Fantom-Factory repository:
** 
**   C:\> fpm install -r fantomFactory lib/myGame.pod
** 
@NoDoc	// Fandoc is only saved for public classes
class InstallCmd : FpmCmd {
	
	@Opt { aliases=["r"]; help="Name or location of the repository to install to (defaults to 'default')" }
	Str? repo

	@NoDoc @Opt { aliases=["c"]; help="Query for Fantom core pods" } 
	Bool core
	
	@Opt { aliases=["u"]; help="Username for authentication" }
	Str? username
	
	@Opt { aliases=["p"]; help="Password for authentication" }
	Str? password
	
	@Arg { help="location or query for pod" }
	Str[]? pod

	new make() : super.make() { }

	override Int go() {
		printTitle
		pod 	:= this.pod.join(" ")
		podFile := FileUtils.toFile(pod)
		if (podFile.exists) {
			podManager.publishPod(podFile, repo)
			return 0
		}

		// if the dest repo is remote, 
		// ...query the local repos and publish to the remote
		if (repo != null) {
			fanrUrl	:= repo?.toUri
			if (fpmConfig.fanrRepos.containsKey(repo) || fanrUrl.scheme == "http" || fanrUrl.scheme == "https") {
				podFiles := podManager.queryLocalRepositories(pod)
				if (podFiles.isEmpty)
					throw Err("Could not find pod '${pod}'")
				podFile = podFiles.first.file
				podManager.publishPod(podFile, repo, username, password)
			}
		}

		// TODO pod URIs to specify which repo to search -> fanr:release/afIoc@2.0 ???
		
		// ...query the remote repos, download, and publish to local
		query := pod.replace("@", " ")
		installed := fpmConfig.fanrRepos.any |url, name->Bool| {
			repo  := fpmConfig.fanrRepo(name, username, password)
			log.info("Querying ${name} for: ${query}")
			specs := repo.query(query, 1)
			if (specs.isEmpty) return false
			
			log.info("Downloading ${specs.first} from ${name}")
			temp := File.createTemp("afFpm-", ".pod").deleteOnExit
			out  := temp.out
			repo.read(specs.first).pipe(out)
			out.close

			publishedPod := podManager.publishPod(temp, this.repo)
			
			
			log.info("")
			log.info("Checking if dependencies need updating...")
			log.info("")
			(log as StdLogger)?.indent
			podDepends := PodDependencies(fpmConfig, File[,], log)
			podDepends.setRunTarget(publishedPod.asDepend)
			UpdateCmd {
				// don't bother re-calculating the fpmConfig - reuse what we have
				it.fpmConfig  = this.fpmConfig
				it.podManager = this.podManager
				it.log		  = this.log
			}.doUpdate(podDepends, this.repo, core)
			(log as StdLogger)?.unindent
			
			
			return true
		}

		if (!installed) {
			log.info("")
			log.info("Could not find: ${query}")
		}
		
		return 0		
	}

	override Bool argsValid() {
		pod != null && pod.size > 0
	}
}
