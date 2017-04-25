using build

class Build : BuildPod {

	new make() {
		podName = "afFpm"
		summary = "Provides a targeted environment for building, testing, and running Fantom applications"
		version = Version("0.0.12")

		meta = [
			"pod.dis"			: "FPM (Fantom Pod Manager)",
			"pod.displayName"	: "FPM (Fantom Pod Manager)",
			"repo.internal"		: "true",
			"repo.tags"			: "system, app",
			"repo.public"		: "true"
		]

		depends = [
			"sys        1.0.67 - 1.0",
			"fanr       1.0.67 - 1.0",
			"util       1.0.67 - 1.0",
			"concurrent 1.0.67 - 1.0",			
			"compiler   1.0.67 - 1.0",		// for afPlastic

//			"afConcurrent 1.0.16 - 1.0",	// for afProcess
		]

		srcDirs = [`fan/`, `fan/afConcurrent/`, `fan/afPlastic/`, `fan/afProcess/`, `fan/internal/`, `fan/internal/cmds/`, `fan/internal/util/`, `fan/public/`, `test/`]
		resDirs = [`doc/`, `res/`]
		
		docApi	= true
		docSrc	= true
	}
}

