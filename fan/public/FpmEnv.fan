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
** 
** Creates a targeted environment for a pod
const class FpmEnv : Env {
	private static const Log log := FpmEnv#.pod.log

	const FpmConfig			fpmConfig

	const Str?				targetPod
	const [Str:PodFile]?	podFiles
	
	new make() : super.make() {
		fpmConfig = FpmConfig()

		try {
			args := Env.cur.vars["FPM_CMDLINE_ARGS"]
			if (args == null)
				log.warn("Env Var 'FPM_CMDLINE_ARGS' not found")
			else {
				podFiles := findPodFiles(fpmConfig, args)
				podName	 := podFiles.remove("fpm-podName")
				this.podFiles = podFiles
				this.targetPod = "${podName.name} ${podName.version}"
				if (targetPod.endsWith(" 0"))
					targetPod += "+"
			}

		} catch (Err err)
//			err.trace
			log.err(err.msg)

		if (podFiles == null)
			log.warn("Defaulting to PathEnv")

		try	log.debug(debug)
		catch (Err err)	err.trace
	}
	
	**
	** Working directory is always first item in `path`.
	**
	override File workDir() {
		fpmConfig.workDirs.first
	}

	**
	** Temp directory is always under `workDir`.
	**
	override File tempDir() {
		fpmConfig.tempDir
	}
	
	override Str[] findAllPodNames() {
		podFiles?.keys ?: parent.findAllPodNames
	}

	override File? findPodFile(Str podName) {
		podFiles?.get(podName)?.file ?: parent.findPodFile(podName)
//		podFiles?.get(podName)?.file ?: resolveLatestPod(podName).file
	}

	override File[] findAllFiles(Uri uri) {
		fpmConfig.workDirs.map { it + uri }.exclude |File f->Bool| { f.exists.not }
	}

	override File? findFile(Uri uri, Bool checked := true) {
		if (uri.isPathAbs) throw ArgErr("Uri must be rel: $uri")
		return fpmConfig.workDirs.eachWhile |dir| {
			f := dir.plus(uri, false)
			return f.exists ? f : null
		} ?: (checked ? throw UnresolvedErr(uri.toStr) : null)
	}

	Str debug() {
		str	:= "\n\n"
		str += "Fantom Pod Manager (FPM) Environment ${typeof.pod.version}\n"
		str += "\n"
		str += "Target Pod : ${targetPod}\n"
		str += fpmConfig.debug

		podFiles := podFiles ?: Str:PodFile[:]
		str += "\n"
		str += "Referencing ${podFiles.size} pods:\n"
		
		maxNom := podFiles.reduce(0) |Int size, podFile| { size.max(podFile.name.size) } as Int
		maxVer := podFiles.reduce(0) |Int size, podFile| { size.max(podFile.version.toStr.size) }
		podFiles.keys.sort.each |key| {
			podFile := podFiles[key]
			str += podFile.name.justr(maxNom + 2) + " " + podFile.version.toStr.justl(maxVer) + " - " + podFile.file.osPath + "\n"
		}
		str += "\n"
		return str
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
	
	private static [Str:PodFile]? findPodFiles(FpmConfig fpmConfig, Str? cmdLineArgs) {
		// add F4 pod locations
		f4PodPaths	:= Env.cur.vars["F4PODENV_POD_LOCATIONS"]?.trimToNull?.split(File.pathSep.chars.first, true) ?: Str#.emptyList
		f4PodFiles	:= f4PodPaths.map { toFile(it) }

		podDepends	:= PodDependencies(fpmConfig, f4PodFiles)
		cmdArgs		:= splitStr(cmdLineArgs)
		buildPod	:= getBuildPod(cmdArgs.first)
		podName		:= null as Depend
		
		if (buildPod != null) {
			buildPod.depends.each {
				podDepends.addPod(Depend(it))		
			}
			podName	= Depend("${buildPod.podName} ${buildPod.version}")
		}
		
		if (podDepends.isEmpty) {
			podDepend := findPodDepend(cmdArgs.first)
			
			// given we're making a targeted environment, this is a fail safe / get out jail card 
			if (podDepend == null) {
				idx := cmdArgs.index("-fpmPod")
				if (idx != null)
					podDepend = findPodDepend(cmdArgs.getSafe(idx + 1))
			}
			
			if (podDepend != null) {
				podDepends.addPod(podDepend).pickLatestVersion
				podName	= podDepend
			}
		}

		if (podDepends.isEmpty)
			log.warn("Could not parse pod from: ${cmdArgs.first}")
		
		return podDepends.satisfyDependencies.podFiles.add("fpm-podName", PodFile {
			it.name = podName.name
			it.version = podName.version
			it.file	= ``.toFile
		})
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

//	private PodVersion resolveLatestPod(Str podName) {
//		PodResolvers(fpmConfig, FileCache()).resolve(Depend("${podName} 0+")).sort.last		
//	}

	private static BuildPod? getBuildPod(Str? filePath) {
		try {
			if (filePath == null)
				return null
			file := filePath.startsWith("file:") ? File(filePath.toUri, false) : File.os(filePath)
			if (file.isDir || file.exists.not || file.ext != "fan")
				return null
			
			// use Plastic because the default pod name when running a script (e.g. 'build_0') is already taken == Err
			return PlasticCompiler().compileCode(file.readAllStr).types.find { it.fits(BuildPod#) }?.make
		} catch
			return null
	}
	
	private static File toFile(Str filePath) {
		file := filePath.startsWith("file:") ? File(filePath.toUri, false) : File.os(filePath)
		return file.normalize
	}
}
