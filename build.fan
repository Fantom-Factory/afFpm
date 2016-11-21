using build

class Build : BuildPod {

	new make() {
		podName = "afFpm"
		summary = "Provides a targeted environment for building, testing, and running Fantom applications"
		version = Version("0.0.10")

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
			"compiler   1.0.67 - 1.0",	// for afPlastic			
		]

		srcDirs = [`fan/`, `fan/afPlastic/`, `fan/internal/`, `fan/internal/cmds/`, `fan/internal/util/`, `fan/public/`, `test/`]
		resDirs = [`doc/`, `res/`]
		
		docApi	= true
		docSrc	= true
	}
}

