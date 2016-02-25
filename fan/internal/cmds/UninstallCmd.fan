using util

@NoDoc
class UnInstallCmd : FpmCmd {
	
	@Opt { aliases=["r"]; help="Name of the file / fanr repository to un-install from" }
	Str repo	:= "default"

	@Opt { aliases=["p"]; help="The name of the pod to uninstall. e.g. myPod@1.2" }
	Str? pod
	
	new make() { }

	override Int go() {
		podManager.uninstallPod(pod, repo)
		return 0
	}
	
	override Bool argsValid() {
		pod != null
	}
}
