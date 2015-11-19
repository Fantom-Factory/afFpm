using build
using util

class PublishCmd : FpmCmd {
	
	@Opt { aliases=["r"]; help="Name of the repository to publish to" }
	Str? repo	:= "default"

	@Opt { aliases=["p"]; help="The path to the pod to publish" }
	File? pod
	
	private PodFile?	podFile
	private File?		libDir
	private CorePods	corePods	:= CorePods()
	
	new makeDefault() { }

	new makeFromFile(PodFile podFile) {
		this.podFile = podFile
	}
	
	new makeFromBuild(BuildPod buildPod) {
		this.podFile = PodFile {
			it.file 	= buildPod.outPodDir.plusName("${buildPod.podName}.pod").toFile
			it.name		= buildPod.podName
			it.version	= buildPod.version
		}
	}

	@NoDoc
	new makeFromLibDir(File libDir) {
		this.libDir = libDir
		// TODO: validate is valid dir file
	}
	
	override Int run() {
		super.parseArgs(Env.cur.args[1..-1])
		if (pod == null)
			throw ArgErr("Argument -pod not defined")
		podVer	:= FileCache.readFile(pod)
		podFile = PodFile {
			it.name = podVer.name
			it.version = podVer.version
			it.file	= pod
		}
		go
		return 0
	}

	override Void go() {
		if (podFile != null) publishPod(podFile) ; else publishAllPods(libDir)
	}
	
	private Void publishAllPods(File libDir) {
		libDir.listFiles(".+\\.pod".toRegex).each |file| {
			if (corePods.isCorePod(file.basename).not)
				if (publishPod(PodFile(file)))
					file.delete
		}
	}

	private Bool publishPod(PodFile podFile) {
		if (podFile.name == typeof.pod.name) {
			log.info("Ignoring ${podFile}")
			return false
		}

		// TODO: allow repo to be a dir path
		log.info("Publishing ${podFile}")
		repoFile := config.repoDirs[repo] + `${podFile.name}/${podFile.name}-${podFile.version}.pod`
		podFile.file.copyTo(repoFile, ["overwrite" : true])
		return true
	}
}