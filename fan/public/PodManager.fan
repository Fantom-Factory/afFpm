
const class PodManager {
	const Log 			log 			:= PodManager#.pod.log

	const FpmConfig		config

	private const CorePods	corePods	:= CorePods()

	new make(|This|? in := null) {
		in?.call(this)
		if (config == null)
			config = FpmConfig()
	}

	PodFile publishPod(File pod, Str repo) {
		_publishPod(PodFile(pod))
	}

	Void publishAllPods(File dir, Str? repo := null) {
		log.info("Publishing pods from ${dir.osPath} into repo '" +  (repo ?: "default") + "'...")
		podFiles := dir.listFiles(".+\\.pod".toRegex).exclude {
			corePods.isCorePod(it.basename) || it.basename == "afFpm"
		}
		if (podFiles.isEmpty)
			log.info("  No pods found")
		
		podFiles.each |file| {
			podFile := PodFile(file)
			_publishPod(podFile, repo)
		}
	}

	PodFile? findPodFile(Str query, Bool checked := true) {
		findAllPodFiles(query).last ?: (checked ? throw Err("Could not find pod '${query}'") : null)
	}

	PodFile[] findAllPodFiles(Str query) {
		PodResolvers(config, File#.emptyList, FileCache()).resolve(Depend(query)).sort.map { it.toPodFile }
	}
	
	private PodFile _publishPod(PodFile podFile, Str? repo := null) {
		if (podFile.file.exists.not)
			throw IOErr(ErrMsgs.mgr_podFileNotFound(podFile.file))

		// note the manual indent!
		log.info("  Publishing ${podFile}")

		// TODO: allow repo to be a dir path
		repoFile := config.repoDirs[repo ?: "default"] + `${podFile.name}/${podFile.name}-${podFile.version}.pod`
		podFile.file.copyTo(repoFile, ["overwrite" : true])
		return podFile
	}
	
//	private FileCache fileCache() { FileCache() }
}
