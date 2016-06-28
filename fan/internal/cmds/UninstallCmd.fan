using util

** Un-installs a pod from a local repository.
** 
** The repository may be:
**  - a named local repository (e.g. 'default')
**  - the directory of a local repository (e.g. 'C:\repo-release\')
**
** Examples: 
**   C:\> fpm uninstall myPod
**   C:\> fpm uninstall -r default myPod 2.0.10
** 
@NoDoc	// Fandoc is only saved for public classes
class UninstallCmd : FpmCmd {
	
	@Opt { aliases=["r"]; help="Name or location of the repository to un-install from (defaults to 'default')" }
	Str? repo

	@Arg { help="The pod to uninstall" }
	Str[]? pod
	
	new make() : super.make() { }

	override Int go() {
		printTitle
		pod := this.pod.join(" ")
		podManager.unPublishPod(pod, repo)
		return 0
	}
	
	override Bool argsValid() {
		pod != null && pod.size > 0
	}
}
