using build
using util

internal class PublishCmd : FpmCmd {
	
	@Opt { aliases=["r"]; help="Name of the file / fanr repository to publish to" }
	Str repo	:= "default"

	@Opt { aliases=["p"]; help="The pod to publish. May be relative and / or OS specific, e.g. pods\\myPod.pod" }
	File? pod
	
	new make() { }

	new makeFromBuild(BuildPod buildPod) {
		this.pod = buildPod.outPodDir.plusName("${buildPod.podName}.pod").toFile
	}

	override Void go() {
		podManager.publishPod(pod, repo)
	}
	
	override Bool argsValid() {
		pod != null
	}
}