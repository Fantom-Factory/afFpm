using build

class PublishCmd : FpmCmd {
	
	private PodFile?	podFile
	private File?		libDir
	private CorePods	corePods	:= CorePods()
	
//	new make(PodFile podFile) {
//		this.podFile = podFile
//	}
	
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

		log.info("Publishing ${podFile}")
		repoFile := config.repoDir + `${podFile.name}/${podFile.name}-${podFile.version}.pod`
		podFile.file.copyTo(repoFile, ["overwrite" : true])
		return true
	}
}