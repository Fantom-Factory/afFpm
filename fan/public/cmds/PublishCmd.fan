using build
using util

class PublishCmd : FpmCmd {
	
	@Opt { aliases=["r"]; help="Name of the repository to publish to" }
	Str? repo	:= "default"

	@Opt { aliases=["p"]; help="The path to the pod to publish" }
	File? pod
	
	private File?	podFile
	private File?	libDir
	
	new makeDefault() { }

	new makeFromPodFile(File file) {
		this.podFile = file
	}
	
	new makeFromBuild(BuildPod buildPod) {
		this.podFile = buildPod.outPodDir.plusName("${buildPod.podName}.pod").toFile
	}

	@NoDoc
	new makeFromLibDir(Uri libDir) {
		this.libDir = libDir.toFile
		// TODO: validate is valid dir file
	}
	
	override Int run() {
		super.parseArgs(Env.cur.args[1..-1])
		if (pod == null)
			throw ArgErr("Argument -pod not defined")
		podFile = pod
		go
		return 0
	}

	override Void go() {
		if (podFile != null)
			PodManager().publishPod(podFile, repo)
		if (libDir != null)
			PodManager().publishAllPods(libDir)
	}
}