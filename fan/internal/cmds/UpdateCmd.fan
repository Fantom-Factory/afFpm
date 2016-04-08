using util
using fanr::PodSpec

// can this install from scratch AND update an existing?
// TODO: can the Update cmd be merged with Install?
** Updates and installs dependencies for a named pod / build file.
** 
** Queries remote repositories looking for newer pod versions that match the 
** targeted FPM environment.
** 
** Examples:
** 
**   C:\> fpm update
**   C:\> fpm update -r default build.fan
**   C:\> fpm update -r release myPod 2.0.10
** 
@NoDoc	// Fandoc is only saved for public classes
class UpdateCmd : FpmCmd {

	@NoDoc @Opt { aliases=["n"]; help="Number of pod versions to query" } 
	Int numVersions	:= 5
	
	@NoDoc @Opt { aliases=["c"]; help="Query for Fantom core pods" } 
	Bool core
	
	@Opt { aliases=["r"]; help="Name or location of the local repository to install pods to (defaults to 'default')" }
	Str repo	:= "default"

	// TODO update, resolving ALL pods
//	@Opt { aliases=["a"]; help="By default FPM will only query for pods newer than the ones on your file system. This option will look for ALL pods, but at the expense of a much slower resolution." }
//	Str all	:= "all"

	@Arg { help="The pod whose dependencies are to be updated" }
	Str[]? pod

	new make() : super.make() { }

	override Int go() {
		printTitle
		podDepends	:= PodDependencies(fpmConfig, File[,], log)
		pod 		:= this.pod?.join(" ")
		
		if (pod != null && !pod.endsWith(".fan")) {
			podFile	:= null as PodFile
			file	:= FileUtils.toFile(pod)
			if (file.exists)
				podFile = PodFile(file)
			else {
				podFiles := podManager.queryLocalRepositories(pod)
				if (podFiles.isEmpty)
					throw Err("Could not find pod '${pod}'")
				podFile = podFiles.first
			}			
			podDepends.setRunTarget(podFile.asDepend)
		}
		
		if (pod == null || pod.endsWith(".fan")) {
			// TODO parse script for "using" statements and update those
			buildPod	:= BuildPod(pod ?: "build.fan")
			if (buildPod == null) {
				log.err("Could not find / load 'build.fan'")
				return 101
			}
			podDepends.setBuildTargetFromBuildPod(buildPod, false)
		}		

		
		doUpdate(podDepends, repo, core)
		log.info("")
		log.info("Done.")
		return 0
	}
	
	internal Void doUpdate(PodDependencies podDepends, Str? repo, Bool queryCore) {
		podDepends.podResolvers.addRemoteRepos(numVersions, queryCore, log)
		podDepends.satisfyDependencies

		if (podDepends.unresolvedPods.size > 0) {
			log.warn(Utils.dumpUnresolved(podDepends.unresolvedPods))
			return 102
		}

		toUpdate := podDepends.podFiles.vals.findAll { it.url.scheme == "fanr" }
		log.info("")

		if (toUpdate.size == 0) {
			log.info("Nothing to update.")
		}
		
		toUpdate.each |podFile| {
			log.info("Downloading ${podFile} from ${podFile.url.host}")

			in := fpmConfig.fanrRepo(podFile.url.host).read(PodSpec([
				"pod.name"		: podFile.name,
				"pod.version"	: podFile.version.toStr,
				"pod.depends"	: "",
				"pod.summary"	: "",
			], null))
			file := File.createTemp("${podFile.name}-", ".pod")
			out  := file.out(false, 16 * 1024)
			try	in.pipe(out)
			finally out.close
			
			podManager.publishPod(file, repo)
		}		
	}
	
	override Bool argsValid() { true }
}
