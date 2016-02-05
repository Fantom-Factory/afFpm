using util
using fanr::PodSpec

// can this install from scratch AND update an existing?
internal class UpdateCmd : FpmCmd {

	@Opt { aliases=["r"]; help="Name of the local repository to publish pods to" }
	Str repo	:= "default"

	override Void go() {
		
		buildPod	:= FpmEnvDefault.getBuildPod("build.fan")		
		if (buildPod == null) {
			// TODO download dependencies for a specific build file / local pod / pod file
			return log.err("Could not find / load 'build.fan'")
		}
		
		podDepends	:= PodDependencies(fpmConfig, File[,])
		podDepends.setBuildTarget(buildPod.podName, buildPod.version, buildPod.depends.map { Depend(it, false) }.exclude { it == null }, false)
		podDepends.podResolvers.addRemoteRepos
		podDepends.satisfyDependencies

		if (podDepends.unresolvedPods.size > 0)
			return log.warn(Utils.dumpUnresolved(podDepends.unresolvedPods))

		toUpdate := podDepends.podFiles.vals.findAll { it.url.scheme == "fanr" }
		if (toUpdate.isEmpty)
			return log.info("All pods are up to date!")

		// TODO only use fanr pods that are greater than our current env 
//		toUpdate.each |podFile| {
//			log.info("  Downloading ${podFile} from ${podFile.url.host}")
//
//			in := fpmConfig.fanrRepo(podFile.url.host).read(PodSpec([
//				"pod.name"		: podFile.name,
//				"pod.version"	: podFile.version.toStr,
//				"pod.depends"	: "",
//				"pod.summary"	: "",
//			], null))
//			file := File.createTemp("${podFile.name}-", ".pod")
//			out  := file.out(false, 16 * 1024)
//			try	in.pipe(out)
//			finally out.close
//			
//			podManager.publishPod(file, repo)
//		}
		log.info("Done.")
	}
	
	override Bool argsValid() { true }
}
