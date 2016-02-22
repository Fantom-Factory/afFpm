using util
using fanr::PodSpec

// can this install from scratch AND update an existing?
** Updates dependencies for a named pod / build file.
internal class UpdateCmd : FpmCmd {

	@Opt { aliases=["r"]; help="Name of the local repository to publish pods to" }
	Str repo	:= "default"

	@Opt { aliases=["p"]; help="The pod whose dependencies are to be updated. Examples, afIoc, afBedSheet@1.5, pods\\myPod.pod" }
	Str? pod

	// TODO update, resolving ALL pods
//	@Opt { aliases=["a"]; help="By default FPM will only query for pods newer than the ones on your file system. This option will look for ALL pods, but at the expense of a much slower resolution." }
//	Str all	:= "all"

	override Int go() {
		podDepends	:= PodDependencies(fpmConfig, File[,], log)

		if (pod != null) {
			file := pod.contains("\\") ? File.os(pod) : pod.toUri.toFile
			podFile := file.exists ? PodFile(file) : podManager.findPodFile(pod, true)
			podDepends.setRunTarget(podFile.asDepend)
		}
		
		if (pod == null) {
			// TODO download dependencies for a specific build file
			buildPod	:= FpmEnvDefault.getBuildPod("build.fan")		
			if (buildPod == null) {
				log.err("Could not find / load 'build.fan'")
				return 101
			}
			podDepends.setBuildTargetFromBuildPod(buildPod, false)
		}		

		
		
		podDepends.podResolvers.addRemoteRepos
		podDepends.satisfyDependencies

		if (podDepends.unresolvedPods.size > 0) {
			log.warn(Utils.dumpUnresolved(podDepends.unresolvedPods))
			return 102
		}

		toUpdate := podDepends.podFiles.vals.findAll { it.url.scheme == "fanr" }

		toUpdate.each |podFile| {
			log.info("  Downloading ${podFile} from ${podFile.url.host}")

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
		log.info("\n")
		log.info("All pods are up to date!")
		log.info("Done.")
		return 0
	}
	
	override Bool argsValid() { true }
}
