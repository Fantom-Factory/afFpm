using build

class Build : BuildPod {

	new make() {
		podName = "afFpmV2"
		summary = "Provides a targeted environment for building, testing, and running Fantom applications"
		version = Version("0.2.0")

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
		]

		srcDirs = [`fan/`, `fan/afConcurrent/`, `fan/afPlastic/`, `fan/afProcess/`, `fan/internal/`, `fan/internal/cmds/`, `fan/internal/repos/`, `fan/internal/resolve/`, `fan/internal/utils/`, `fan/public/`, `test/`]
		resDirs = [`doc/`, `res/`]
		
		docApi	= true
		docSrc	= true
	}
}

