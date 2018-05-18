
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
	Str? pod

	new make(|This| f) : super(f) {
		if (repo == null) repo = fpmConfig.repository("default")
		
		// set any given credentials
		if (username != null || password != null)
			repo = fpmConfig.repository(repo.name, username, password)
		
		if (pod == null)
			pod = "build.fan"
	}

	override Int run() {
		log.info("FPM installing ${pod}")

		resolver := Resolver(fpmConfig.repositories { remove(repo) })
		resolver.maxPods	= 1
		resolver.corePods	= core
		resolver.log		= log
		
		file := FileUtils.toFile(pod)
		if (file.exists) {
			
			// install a single pod
			if (file.ext == "pod") {
				SinglePodRepository(file).podFile.installTo(repo)
				return 0
			}
			
			// update a build file
			if (file.ext == "fan" && file.basename == "build") {
				buildPod := BuildPod(file.name)

				if (buildPod.errMsg != null) {
					// TODO parse fan scripts for "using" statements and update those
					log.err(buildPod.errMsg)
					return invalidArgs
				}

				// update
				pods := resolver.satisfyBuild(buildPod).findAll { it.repository.isRemote }
				pods.each |p| {
					log.info("Downloading ${p.depend} from ${p.repository.name} (${p.repository.url})")
					p.installTo(repo)
				}
				return 0
			}
			
			
			// install a directory of pods
			if (file.isDir) {
				pods := file.listFiles(Regex.glob("*.pod"))
				pods.each |pod| {
					SinglePodRepository(pod).podFile.installTo(repo)
				}
				if (pods.isEmpty)
					log.warn("No pods found in: $file.normalize.osPath")
				return 0
			}

			throw Err("Only pods (or a directory of pods) may be installed")
		}
		
		// if the dest repo is remote... 
		//    ...query the local repos and publish to the remote
		if (repo.isRemote) {
			resolver.localOnly
			pods := resolver.resolve(parseTarget(pod))
			if (pods.isEmpty)
				throw Err("Could not find pod: ${pod}")

			pods.first.installTo(repo)
			return 0
		}

		// if the dest repo is local... (which it must be)
		//    ...query the remote repos and publish to the local
		if (repo.isLocal) {
			newPod := resolver.resolve(parseTarget(pod)).first
			if (newPod == null)
				throw Err("Could not find pod: ${newPod}")

			log.info("Downloading ${newPod.depend} from ${newPod.repository.name} (${newPod.repository.url})")
			newPod.installTo(repo)

			// update
			pods := resolver.satisfyPod(parseTarget(pod)).findAll { it.repository.isRemote }
			pods.each |p| {
				log.info("Downloading ${p.depend} from ${p.repository.name} (${p.repository.url})")
				p.installTo(repo)
			}
			
			return 0
		}
		
		return 0
	}
	
	private static Depend? parseTarget(Str arg) {
		dep := arg.replace("@", " ")
		if (!dep.contains(" "))
			dep += " 0+"
		return Depend(dep, true)
	}
}
