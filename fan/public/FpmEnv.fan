using build
using concurrent

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
	private const Log log := FpmEnv#.pod.log

	const Str:PodFile	podFiles
	
	const FpmConfig		fpmConfig
	
	new make() : super.make() {
		fpmConfig	= FpmConfig()
		podDepends	:= PodDependencies(fpmConfig)
		cmdArgs		:= (Str[]) (Env.cur.vars["FPM_CMDLINE_ARGS"]?.split ?: Str#.emptyList)	// TODO: honour "path with spaces/build.fan"
		
		firstArg	:= cmdArgs.first
		podDepend 	:= findPodDepend(firstArg)
		if (firstArg != null && firstArg.contains(File.sep))
			firstArg = firstArg[firstArg.index(File.sep)..-1]
		
		if (firstArg == "build.fan") {
			bob := loadBuild
			if (bob != null) {
				bob.depends.each {
					podDepends.addPod(Depend(it))				
				}
			} else
				log.warn("Defaulting to latest pod versions - File 'build.fan' not found")

		} else if (podDepend != null) {
		
			podDepends.addPod(podDepend).pickLatestVersion

		} else if (firstArg != null) {
			log.warn("Defaulting to latest pod versions - Unknown 'FPM_CMDLINE_ARGS' - $firstArg")

		} else {
			log.warn("Defaulting to latest pod versions - Env Var 'FPM_CMDLINE_ARGS' not found")
		}
		
		this.podFiles = podDepends.satisfyDependencies.podFiles
		
		// TODO: debug print env details
		echo(podFiles.vals)		
	}
	
	**
	** Working directory is always first item in `path`.
	**
	override File workDir() {
		fpmConfig.workDir
	}

	**
	** Temp directory is always under `workDir`.
	**
	override File tempDir() {
		fpmConfig.workDir
	}
	
	override Str[] findAllPodNames() {
		podFiles.keys.addAll(super.findAllPodNames).unique
	}

	override File? findPodFile(Str podName) {
		podFiles[podName]?.file
	}

	override File[] findAllFiles(Uri uri) {
		echo("=======q;;= looking for $uri")
		return super.findAllFiles(uri)		
	}

	override File? findFile(Uri uri, Bool checked := true) {
		echo("======== looking for $uri")
		return super.findFile(uri, checked)
	}

	private static Depend? findPodDepend(Str? arg) {
		if (arg == null)
			return null

		// TODO: check for version e.g. afIoc@3.0
		dependStr := (Str?) null
		if (arg.all { isAlphaNum })
			dependStr = arg

		if (dependStr == null && arg.all { isAlphaNum || equals(':') || equals('.') } && arg.contains("::"))
			dependStr = arg[0..<arg.index("::")]

		// double check valid pod names
		if (dependStr.all { isAlphaNum }.not)
			return null
		
		dependStr += " 0+"

		return Depend(dependStr, true)
	}
	
	private static BuildPod? loadBuild() {
		buildFan := (File?) File(`build.fan`).normalize
		while (buildFan != null && !buildFan.exists)
			buildFan = buildFan.parent.parent?.plus(`build.fan`)
		// use Plastic because the default pod name when running a script (e.g. 'build_0') is already taken == Err
		return buildFan == null ? null : PlasticCompiler().compileCode(buildFan.readAllStr).types.find { it.fits(BuildPod#) }.make
	}
}
