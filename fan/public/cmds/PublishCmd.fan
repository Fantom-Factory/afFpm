using build

class PublishCmd : FpmCmd {
	
	PodFile	podFile
	
	new make(PodFile podFile) {
		this.podFile = podFile
	}
	
	new makeFromBuild(BuildPod buildPod) {
		this.podFile = PodFile {
			it.file 	= buildPod.outPodDir.plusName("${buildPod.podName}.pod").toFile
			it.name		= buildPod.podName
			it.version	= buildPod.version
		}
	}
	
	Void run() {
		fanrDir	 := `file:/C:/Repositories/Fantom/repo/`
		repoFile := (fanrDir + `${podFile.name}/${podFile.name}-${podFile.version}.pod`).toFile
		podFile.file.copyTo(repoFile, ["overwrite" : true])
	}
}