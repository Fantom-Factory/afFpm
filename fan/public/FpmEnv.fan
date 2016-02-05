
** Provides a targeted environment for a pod. 
** Always provides access to all the libs in HomeDir and WorkDirs as a fail safe! (
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
abstract const class FpmEnv : Env {
	private static const Log 	log 	:= FpmEnv#.pod.log

	const Err?				error				
	const FpmConfig			fpmConfig
	const Str:PodFile		resolvedPodFiles
	const Str:PodFile		allPodFiles
	
	const Str				targetPod
	const UnresolvedPod[]	unresolvedPods
	
	private const File[]	fileDirs
	
	static new make() {
		FpmEnvDefault()
	}

	new makeManual(FpmConfig fpmConfig, File[] f4PodFiles, |This|? in := null) : super.make() {
		in?.call(this)	// can't do field null comparison without an it-block ctor

		this.fpmConfig	= fpmConfig
		this.fileDirs	= fpmConfig.podDirs.dup.addAll(fpmConfig.workDirs).add(fpmConfig.homeDir)
		podDepends		:= PodDependencies(fpmConfig, f4PodFiles)

		try {
			findTarget(podDepends)
			podDepends.satisfyDependencies
			
			resolvedPodFiles		= podDepends.podFiles
			targetPod				= podDepends.targetPod ?: "???"
			unresolvedPods			= podDepends.unresolvedPods
			if (targetPod.endsWith(" 0"))
				targetPod += "+"

			// add all (unresolved) pods from the the home and work dirs
			podFiles	:= resolvedPodFiles.dup.rw
			if (podDepends.building != null)
				podFiles.remove(podDepends.building)
			podRegex	:= ".+\\.pod".toRegex
			// note that workDirs includes homeDir
			fpmConfig.podDirs .each {              (it).listFiles(podRegex).each { if (it.isDir.not && podFiles.containsKey(it.basename).not) podFiles[it.basename] = PodFile(it) } }
			fpmConfig.workDirs.each { (it + `lib/fan/`).listFiles(podRegex).each { if (it.isDir.not && podFiles.containsKey(it.basename).not) podFiles[it.basename] = PodFile(it) } }

			this.allPodFiles = podFiles

		} catch (UnknownPodErr err) {
			// TODO: auto-download / install the pod dependency!
			// beware, also thrown by BuildPod on malformed dependency str
			error = err

		} catch (Err err) {
			error = err

		} finally {
			this.unresolvedPods		= this.unresolvedPods	!= null ? this.unresolvedPods	: [,]
			this.resolvedPodFiles	= this.resolvedPodFiles	!= null ? this.resolvedPodFiles	: [:]
			this.allPodFiles 		= this.allPodFiles		!= null ? this.allPodFiles		: [:]
			this.targetPod			= this.targetPod		!= null ? this.targetPod		: "???"
		}
		
		if (targetPod == "???") {
			log.warn("Could not target pod - defaulting to latest pod versions")
			this.allPodFiles = podDepends.podResolvers.resolveAll(allPodFiles.rw)
		}

		if (Env.cur.vars["FPM_ALL_PODS"]?.toBool(false) ?: false) {
			log.warn("FPM_ALL_PODS = true; defaulting to latest pod versions")
			this.allPodFiles = podDepends.podResolvers.resolveAll(allPodFiles.rw)			
		}
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
		allPodFiles.keys 
	}

	override File? findPodFile(Str podName) {
		allPodFiles.get(podName)?.file
	}

	override File[] findAllFiles(Uri uri) {
		fileDirs.map { it + uri }.exclude |File f->Bool| { f.exists.not }
	}

	override File? findFile(Uri uri, Bool checked := true) {
		if (uri.isPathAbs) throw ArgErr("Uri must be rel: $uri")
		return fileDirs.eachWhile |dir| {
			f := dir.plus(uri, false)
			return f.exists ? f : null
		} ?: (checked ? throw UnresolvedErr(uri.toStr) : null)
	}

	@NoDoc
	internal abstract Void findTarget(PodDependencies podDepends)
		
	** Dumps debug output to a string.
	Str dump() {
		str	:= "\n\n"
		str += "FPM Environment:\n"
		str += "\n"
		str += "   Target Pod : ${targetPod}\n"
		str += fpmConfig.dump

		str += "\n"
		str += "Resolved ${resolvedPodFiles.size} pod" + (resolvedPodFiles.size == 1 ? "" : "s") + (resolvedPodFiles.size == 0 ? "" : ":") + "\n"
		
		maxNom := resolvedPodFiles.reduce(0) |Int size, podFile| { size.max(podFile.name.size) } as Int
		maxVer := resolvedPodFiles.reduce(0) |Int size, podFile| { size.max(podFile.version.toStr.size) }
		resolvedPodFiles.keys.sort.each |key| {
			podFile := resolvedPodFiles[key]
			str += podFile.name.justr(maxNom + 2) + " " + podFile.version.toStr.justl(maxVer) + " - " + podFile.file.osPath + "\n"
		}
		str += "\n"
		
		// unsatisfied constraints and errors should be logged separately after this dump 

		return str
	}
}
