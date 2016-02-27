using util
using fanr

** Installs a pod to a repository.
** 
** The repository may be:
**  - a named local repository. Example, 'default'
**  - a named remote repository. Example, 'fantomFactory'
**  - the directory of a local repository. Example, 'C:\repo-release\'
**  - the URL of a remote repositry. Example, 'http://pods.fantomfactory.org/fanr/'
** 
** The pod may be:
**  - a file location, absolute or relative. Example, 'lib/myAweseomeGame.pod'
**  - a simple search query. Example, '"afIoc 3.0"' or 'afIoc@3.0'
** 
** All the above makes the 'install' command very versatile. Some examples:
** 
** To download the latest pod from a remote repository:
** 
**   > fpm install -p afIoc
** 
** To download a specific pod version to a local repository:
** 
**   > fpm install -p afIoc@2.0.10 -r release
** 
** To publish (upload) a pod to the Fantom-Factory repository:
** 
**   > fpm install -p lib/myGame.pod -r fantomFactory
** 
** To publish (upload) a specific pod version to the Fantom-Factory repository:
** 
**   > fpm install -p myGame@2.0 -r fantomFactory
** 
@NoDoc
class InstallCmd : FpmCmd {
	
	@Opt { aliases=["r"]; help="Name or location of the repository to install to." }
	Str? repo

	@Opt { aliases=["p"]; help="The pod to install. May be a file location or search query." }
	Str? pod

	override Int go() {

		podFile := FileUtils.toFile(pod)
		if (podFile.exists) {
			podManager.publishPod(podFile, repo)
			return 0
		}

		// if the dest repo is remote, 
		// ...query the local repos and publish to the remote
		fanrUrl	:= repo.toUri
		if (fpmConfig.fanrRepos.containsKey(repo) || fanrUrl.scheme == "http" || fanrUrl.scheme == "https") {
			podFiles := podManager.queryLocalRepositories(pod)
			if (podFiles.isEmpty)
				throw Err("Could not find pod '${pod}'")
			podFile = podFiles.first.file
			podManager.publishPod(podFile)
		}

		// TODO pod URIs to specify which repo to search -> fanr:release/afIoc@2.0 ???
		
		// ...query the remote repos, download, and publish to local
		query := pod.replace("@", " ")
		fpmConfig.fanrRepos.find |url, name->Bool| {
			repo  := fpmConfig.fanrRepo(name)
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
		return 0		
	}
		
	override Bool argsValid() {
		pod != null
	}
}
