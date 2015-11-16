using build
using afPlastic

**
** Has to cater for 
**  - building a pod - fan build.fan
**  - running a pod - fan afEggbox
**  - compiling in F4
**  - running from F4
** 
** Does not cater for 
**  - running a script - fan appBuild.fan (should just take latest?)
const class FpmEnv : Env {
	
	const Str:PodFile	podFiles
	
	new make() : super.make() {
		fpmConfig	:= FpmConfig()
		podDepends	:= PodDependencies(fpmConfig)
		cmdArgs		:= (Str[]) (Env.cur.vars["FPM_CMDLINE_ARGS"]?.split ?: Str#.emptyList)	// TODO: honour "path with spaces/build.fan"
		
		firstArg	:= cmdArgs.first ?: ""
		echo(firstArg)
		if (firstArg.contains(File.sep))
			firstArg = firstArg[firstArg.index(File.sep)..-1]

		if (firstArg == "build.fan") {
			bob := loadBuild
			if (bob != null)
				podDepends.addPod(Depend("${bob.podName} ${bob.version}"))
		} else {
		
			// TODO: check for version e.g. afIoc@3.0
			podDepends.addPod(Depend("${firstArg} 0+"))			
		}
		
		this.podFiles = podDepends.satisfyDependencies.podFiles
		
		// TODO: debug print env details
		echo(podFiles.vals)		
	}
	
	override File? findPodFile(Str podName) {
		podFiles[podName]?.file ?: super.findPodFile(podName)
	}

	override Str[] findAllPodNames() {
		podFiles.keys.addAll(super.findAllPodNames).unique
	}

	private static BuildPod? loadBuild() {
		buildFan := (File?) File(`build.fan`).normalize
		while (buildFan != null && !buildFan.exists)
			buildFan = buildFan.parent.parent?.plus(`build.fan`)
		// use Plastic because the default pod name when running a script (e.g. 'build_0') is already taken == Err
		return buildFan == null ? null : PlasticCompiler().compileCode(buildFan.readAllStr).types.find { it.fits(BuildPod#) }.make
	}
}
