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

	const FpmConfig			fpmConfig

	const [Str:PodFile]?	podFiles
	
	new make() : super.make() {
		fpmConfig	= FpmConfig()

		try {
			podDepends	:= PodDependencies(fpmConfig)
			cmdArgs		:= splitStr(Env.cur.vars["FPM_CMDLINE_ARGS"])
			
			firstArg	:= cmdArgs.first
			podDepend 	:= findPodDepend(firstArg)
			if (firstArg != null && firstArg.contains(File.sep))
				firstArg = firstArg[firstArg.index(File.sep)..-1]
			
			if (podDepend == null) {
				idx := cmdArgs.index("-pod")
				if (idx != null)
					podDepend = findPodDepend(cmdArgs.getSafe(idx + 1))
			}
			
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

		} catch (Err err) {
			log.err(err.msg)
			// TODO: log resorting to using latest pods
			// FIXME: NO! fpm should provide a 'targeted' environment for DEV only!
			// TODO: default instead to boot env
		}
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
		// TODO: we should list (and cache) ALL the pods in repo and don't call super
		podFiles?.keys ?: parent.findAllPodNames
	}

	override File? findPodFile(Str podName) {
		podFiles?.get(podName)?.file ?: parent.findPodFile(podName)
//		podFiles?.get(podName)?.file ?: resolveLatestPod(podName).file
	}

	override File[] findAllFiles(Uri uri) {
		fpmConfig.paths.map { it + uri }.exclude |File f->Bool| { f.exists.not }
	}

	override File? findFile(Uri uri, Bool checked := true) {
		if (uri.isPathAbs) throw ArgErr("Uri must be rel: $uri")
		return fpmConfig.paths.eachWhile |dir| {
			f := dir.plus(uri, false)
			return f.exists ? f : null
		} ?: (checked ? throw UnresolvedErr(uri.toStr) : null)
	}

	internal static Str[] splitStr(Str? str) {
		if (str?.trimToNull == null)	return Str#.emptyList
		strings	 := Str[,]
		chars	 := Int[,]
		prev	 := (Int?) null
		inQuotes := false
		str.each |c| {
			if (c.isSpace && inQuotes.not) { 
				if (chars.isEmpty.not) {
					strings.add(Str.fromChars(chars))
					chars.clear
				}
			} else if (c == '"') {
				if (inQuotes.not)
					if (chars.isEmpty)
						inQuotes = true
					else
						chars.add(c)
				else {
					inQuotes = false
					strings.add(Str.fromChars(chars))
					chars.clear					
				}
				
			} else
				chars.add(c)

			prev = null
		}

		if (chars.isEmpty.not)
			strings.add(Str.fromChars(chars))

		return strings
	}
	
	private static Depend? findPodDepend(Str? arg) {
		if (arg == null || arg.endsWith(".fan"))
			return null
		// TODO: check for version e.g. afIoc@3.0
		dependStr := (Str?) null
		if (arg.all { isAlphaNum })
			dependStr = arg

		if (dependStr == null && arg.all { isAlphaNum || equals(':') || equals('.') } && arg.contains("::"))
			dependStr = arg[0..<arg.index("::")]

		// double check valid pod names
		if (dependStr == null || dependStr.all { isAlphaNum }.not)
			return null
		
		dependStr += " 0+"

		return Depend(dependStr, true)
	}

	private PodVersion resolveLatestPod(Str podName) {
		PodResolvers(fpmConfig, FileCache()).resolve(Depend("${podName} 0+")).sort.last		
	}

	private static BuildPod? loadBuild() {
		buildFan := (File?) File(`build.fan`).normalize
		while (buildFan != null && !buildFan.exists)
			buildFan = buildFan.parent.parent?.plus(`build.fan`)
		// use Plastic because the default pod name when running a script (e.g. 'build_0') is already taken == Err
		return buildFan == null ? null : PlasticCompiler().compileCode(buildFan.readAllStr).types.find { it.fits(BuildPod#) }.make
	}
}
