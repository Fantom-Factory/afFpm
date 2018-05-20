
** Installs pods to a repository.
** 
** The pod may be:
**  - a file location       (e.g. 'lib/myGame.pod' or 'C:\lib\myGame.pod')
**  - a simple search query (e.g. 'afIoc@3.0' or '"afIoc 3.0"')
**  - a directory of pods   (e.g. 'lib/' or 'C:\lib\')
**  - a build file          (e.g. 'build.fan' - use to update dependencies) 
** 
** The repository may be:
**  - a named repository    (e.g. 'eggbox')
**  - a local directory     (e.g. 'lib/' or 'C:\lib\')
**  - a remote fanr URL     (e.g. 'http://eggbox.fantomfactory.org/fanr/')
** 
** All the above makes the 'install' command very versatile.
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
	
	@Opt { aliases=["r"]; help="Name or location of repository to install to (defaults to 'default')" }
	Repository repo

	@Opt { aliases=["c"]; help="Query and install Fantom core pods" } 
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
		// because the InstallCmd is so varied, lets have individual titles 
//		log.info("FPM installing ${pod}"))
		
		resolver := Resolver(fpmConfig.repositories)
		resolver.maxPods	= 1
		resolver.corePods	= core
		resolver.log		= log
		
		file := FileUtils.toFile(pod).normalize
		if (file.exists) {
			
			// install a single pod
			if (file.ext == "pod") {
				podFile := PodFile(file)
				log.info("FPM installing ${podFile.depend} to ${repo.name}")
				podFile.installTo(repo)
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
				log.info("FPM updating dependencies for ${buildPod.podName} ...")
				satisfied := resolver.satisfyBuild(buildPod)
				if (satisfied.resolvedPods.isEmpty && satisfied.unresolvedPods.size > 0) {
					log.warn(Utils.dumpUnresolved(satisfied.unresolvedPods.vals))
					return 9
				}
				podFiles := satisfied.resolvedPods.findAll { it.repository.isRemote }
				podFiles.each |podFile| {
					log.info("Installing ${podFile.depend} to ${repo.name} (from ${podFile.repository.name})")
					podFile.installTo(repo)
				}
				if (podFiles.isEmpty)
					log.info("No remote dependencies found.")
				else
					log.info("Done.")
				return 0
			}
			
			// install a directory of pods
			if (file.isDir) {
				log.info("FPM installing pod files from ${file.osPath}")
				files	 := file.listFiles(Regex.glob("*.pod"))
				podFiles := (PodFile[]) files.map { PodFile(it) }
				if (!core) podFiles = podFiles.exclude { it.isCore }
				podFiles.each |podFile| {
					log.info("Installing ${podFile.depend} to ${repo.name}")
					podFile.installTo(repo)
				}
				if (podFiles.isEmpty)
					log.warn("No pods found in: $file.osPath")
				return 0
			}

			throw Err("Only pods (or a directory of pods) may be installed: ${file.osPath}")
		}
		
		target := parseTarget(pod)
		
		// if the dest repo is remote... 
		//    ...query the local repos and publish to the remote
		if (repo.isRemote && target != null) {
			resolver.localOnly
			podFiles := resolver.resolve(target)
			if (podFiles.isEmpty)
				throw Err("Could not find pod: ${target}")

			podFile := podFiles.first
			log.info("FPM uploading ${podFile.depend} to ${repo.name} (${repo.url})")
			podFile.installTo(repo)
			return 0
		}

		// if the dest repo is local... (which it now must be)
		//    ...query the remote repos and publish to the local
		if (repo.isLocal && target != null) {
			newPod := resolver.resolve(target).first
			if (newPod == null)
				throw Err("Could not find pod: ${target}")

			if (newPod.repository != repo) {
				log.info("FPM installing ${newPod.depend} to ${repo.name} (from ${newPod.repository.name})")
				newPod.installTo(repo)
			}

			// update & install dependencies
			log.info("Updating dependencies for ${target} ...")
			satisfied := resolver.satisfyPod(target)
			if (satisfied.resolvedPods.isEmpty && satisfied.unresolvedPods.size > 0) {
				log.warn(Utils.dumpUnresolved(satisfied.unresolvedPods.vals))
				return 9
			}
			podFiles := satisfied.resolvedPods.findAll { it.repository.isRemote }
			podFiles.each |podFile| {
				log.info("Installing ${podFile.depend} to ${repo.name} (from ${podFile.repository.name})")
				podFile.installTo(repo)
			}
			if (podFiles.isEmpty)
				log.info("No remote dependencies found.")
			else
				log.info("Done.")
			return 0
		}
		
		throw Err("Unknown target: $pod")
	}
	
	private static Depend? parseTarget(Str arg) {
		dep := arg.replace("@", " ")
		if (!dep.contains(" "))
			dep += " 0+"
		return Depend(dep, true)
	}
}
