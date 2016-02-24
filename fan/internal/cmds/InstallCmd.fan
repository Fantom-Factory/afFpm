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
		repo := repo ?: ""

		if (fpmConfig.fanrRepos.containsKey(repo))
			installToRemote(fpmConfig.fanrRepo(repo))
		fanrUrl	:= repo.toUri
		if (fanrUrl.scheme == "http" || fanrUrl.scheme == "https")
			installToRemote(FpmConfig.toFanrRepo(fanrUrl))

		if (fpmConfig.fileRepos.containsKey(repo))
			installToLocal(fpmConfig.fileRepos[repo])
		repoDir := FileUtils.toFile(repo)
		if (repoDir.exists)
			installToLocal(repoDir)

		// if no repo is specified, then we assume pod is a search query to install
//		download(repoDir)
//		podFile := FileUtils.toFile(pod)
//			
//		// TODO be nice here
//		err("Unknown repository: ${repo}")

		return 0
	}
	
	private Int installToRemote(Repo repo) {
		return 0
	}
	
	private Int installToLocal(File repoDir) {
//		podManager.install(pod, repo)
		return 0
	}
	
	override Bool argsValid() {
		pod != null
	}
}
