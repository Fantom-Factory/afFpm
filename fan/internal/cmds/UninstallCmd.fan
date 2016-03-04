using util

@NoDoc	// Fandoc is only saved for public classes
class UnInstallCmd : FpmCmd {
	
	@Opt { aliases=["r"]; help="Name of the file / fanr repository to un-install from" }
	Str repo	:= "default"

	@Opt { aliases=["p"]; help="The name of the pod to uninstall. e.g. myPod@1.2" }
	Str? pod
	
	new make() { }

	override Int go() {
		podManager.unPublishPod(pod, repo)
		return 0
	}
	
	override Bool argsValid() {
		pod != null
	}
}
