
const class PodManager {
	const Log 			log 		:= FpmEnv#.pod.log

	const FpmConfig		config

	private const CorePods	corePods	:= CorePods()

	new make(|This|? in := null) {
		in?.call(this)
		if (config == null)
			config = FpmConfig()
	}

	Void publishPod(File pod, Str repo) {
		_publishPod(PodFile(pod))
	}

	Void publishAllPods(File dir, Bool deletePodAfterPublish := true) {
		dir.listFiles(".+\\.pod".toRegex).each |file| {
			podFile := PodFile(file)
			if (corePods.isCorePod(podFile.name) || podFile.name == "afFpm")
				log.info("Ignoring ${podFile}")
			else {
				_publishPod(podFile)
				podFile.file.delete
			}
		}
	}

	private Void _publishPod(PodFile podFile, Str? repo := null) {
		log.info("Publishing ${podFile}")

		// TODO: allow repo to be a dir path
		repoFile := config.repoDirs[repo ?: "default"] + `${podFile.name}/${podFile.name}-${podFile.version}.pod`
		podFile.file.copyTo(repoFile, ["overwrite" : true])
	}
	
//	private FileCache fileCache() { FileCache() }
}
