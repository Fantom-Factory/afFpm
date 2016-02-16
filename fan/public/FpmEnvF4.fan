
@NoDoc
const class FpmEnvF4 : FpmEnv {
	const Str		name
	const Version	version
	const Depend[]	depends
	
	new make(FpmConfig fpmConfig, |This| in) : super.makeManual(fpmConfig, File#.emptyList, in) { }
	
	override internal Void findTarget(PodDependencies podDepends) {
		podDepends.setBuildTarget(name, version, depends, true)
	}
}
