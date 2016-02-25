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
		doRemoteToLocal(pod, fpmConfig.fileRepos["default"])
		
		return 0
	}
	
	private Int installToLocal(File repoDir) {
		podFile := FileUtils.toFile(pod)
		return podFile.exists
			? doLocalToLocal(podFile, repoDir.normalize)
			: doRemoteToLocal(pod, repoDir.normalize)
	}

	private Int installToRemote(Repo fanr) {
		podFile := FileUtils.toFile(pod)
		return podFile.exists
			? doLocalToRemote(podFile, fanr)
			: doRemoteToRemote(pod, fanr)
	}

	private Int doLocalToLocal(File podFile, File repoDir) {
		// installing a local file to a local repo
		podManager.publishPod(podFile, repoDir.osPath)
		return 0
	}
	
	private Int doRemoteToLocal(Str podQuery, File repoDir) {
		// query remote repos, download, & install to local repo
		query := podQuery.replace("@", " ")
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
			
			podManager.publishPod(temp, repoDir.osPath)
			return true
		}
		return 0
	}
	
	private Int doLocalToRemote(File podFile, Repo fanr) {
		// publish the local file to a remote repo
		fanr.publish(podFile)
		return 0
	}
	
	private Int doRemoteToRemote(Str podQuery, Repo fanr) {
		// a misnomer, we actually...
		// query the local repos and publish it to a remote repo
		// thinking of pod URIs to specify which repo to search -> fanr:release/afIoc@2.0 ???
		podFile := podManager.findPodFile(podQuery, false)
		if (podFile != null)
			fanr.publish(podFile.file)
		return 0
	}
	
	override Bool argsValid() {
		pod != null
	}
}
