using util
using fanr

** Installs a pod to a repository.
** 
** The repository may be:
**  - a named local repository. Example, 'default'
**  - a named remote repository. Example, 'fantomFactory'
**  - the directory of a local repository. Example, 'C:\repo-release\'
**  - the URL of a remote repository. Example, 'http://pods.fantomfactory.org/fanr/'
** 
** The pod may be:
**  - a file location, absolute or relative. Example, 'lib/myAweseomeGame.pod'
**  - a simple search query. Example, '"afIoc 3.0"' or 'afIoc@3.0'
** 
** All the above makes the 'install' command very versatile. Some examples:
** 
** To download the latest pod from a remote repository:
** 
**   > fpm install afIoc
** 
** To download a specific pod version to a local repository:
** 
**   > fpm install -r release afIoc@2.0.10
** 
** To publish (upload) a pod to the Fantom-Factory repository:
** 
**   > fpm install -r fantomFactory lib/myGame.pod
** 
@NoDoc	// Fandoc is only saved for public classes
class InstallCmd : FpmCmd {
	
	@Opt { aliases=["r"]; help="Name or location of the repository to install to." }
	Str? repo

	@Opt { aliases=["u"]; help="Username for authentication" }
	Str? username
	
	@Opt { aliases=["p"]; help="Password for authentication" }
	Str? password
	
	@Arg { help="location or query for pod" }
	Str[]? pod

	override Int go() {
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
			log.info("  Querying ${name} for: ${query}")
			specs := repo.query(query, 1)
			if (specs.isEmpty) return false
			
			// FIXME need to download dependencies too!
			
			log.info("  Downloading ${specs.first} from ${name}")
			temp := File.createTemp("afFpm-", ".pod").deleteOnExit
			out  := temp.out
			repo.read(specs.first).pipe(out)
			out.close
			
			podManager.publishPod(temp, this.repo)
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
