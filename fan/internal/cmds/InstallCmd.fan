
** Installs a pod to a repository.
** 
** The pod may be:
**  - a file location, absolute or relative. Example, 'lib/myAweseomeGame.pod'
**  - a simple search query. Example, '"afIoc 3.0"' or 'afIoc@3.0'
**  - a directory of pods, absolute or relative. Example, 'lib/'
** 
** The repository may be:
**  - a named local repository (e.g. 'default')
**  - a named remote repository (e.g. 'fantomFactory')
**  - the directory of a local repository (e.g. 'C:\repo-release\')
**  - the URL of a remote repository (e.g. 'http://eggbox.fantomfactory.org/fanr/')
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
	Repository repo

	@Opt { aliases=["c"]; help="Query for Fantom core pods also" } 
	Bool core
	
	@Opt { aliases=["u"]; help="Username for remote fanr authentication" }
	Str? username
	
	@Opt { aliases=["p"]; help="Password for remote fanr authentication" }
	Str? password
	
	@Arg { help="location or query for pod" }
	Str pod

	new make(|This| f) : super(f) { }

	override Int run() {
		log.info("FPM installing ${pod}")

		// FIXME don't allow local repo dirs or remote repo URLs, only allow "named" repos - then a local dir can be used to collate pods into the one place
		
		file := FileUtils.toFile(pod)
		if (file.exists) {
			if (file.isDir) {
				// FIXME publish a dir of pods!
//				podManager.publishPods(file, repo, username, password)
			} else
				// FIXME check this file is a pod!
				SinglePodRepository(file).podFile.installTo(repo)
			return 0
		}

//		if (pod == null || pod.endsWith(".fan")) {
//			// TODO parse script for "using" statements and update those
//			buildPod := BuildPod(pod ?: "build.fan")
//			if (buildPod.errMsg != null) {
//				log.err("Could not find / load 'build.fan'")
//				return 101
//			}
//			podDepends.setBuildTargetFromBuildPod(buildPod, false)
//		}	
		
		repos := RepoMan(fpmConfig.repositories)
		repos.maxPods	= 1
		repos.corePods	= core
		repos.log		= log
		
		// if the dest repo is remote... 
		//    ...query the local repos and publish to the remote
		if (repo.isRemote) {
			repos.localOnly
			pods := repos.resolve(parseTarget(pod))
			if (pods.isEmpty)
				throw Err("Could not find pod: ${pod}")

			// set any given credentials
			repo = fpmConfig.repository(repo.name, username, password)
			pods.first.installTo(repo)
			return 0
		}

		// if the dest repo is local... (which it must be)
		//    ...query the remote repos and publish to the local
		if (repo.isLocal) {
			repos.remoteOnly
			pods := repos.resolve(parseTarget(pod))
			if (pods.isEmpty)
				throw Err("Could not find pod: ${pod}")

			pods.first.installTo(repo)
//			log.info("Downloading ${specs.first} from ${name}")
			
			
			
			return 0
		}

		// FIXME now update
		
		return 0		
	}
	
	private static Depend? parseTarget(Str arg) {
		dep := arg.replace("@", " ")
		if (!dep.contains(" "))
			dep += " 0+"
		return Depend(dep, true)
	}
}
