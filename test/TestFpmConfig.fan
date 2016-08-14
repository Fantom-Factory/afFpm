
internal class TestFpmConfig : Test {
	
	Void testWorkDirs() {
		homeDir := Env.cur.homeDir
		
		// test default
		config := makeFpmConfig(null, [:])
		verifyEq(config.workDirs.size, 1)
		verifyEq(config.workDirs.first, homeDir)

		// test default 2
		config = makeFpmConfig("", [:])
		verifyEq(config.workDirs.size, 1)
		verifyEq(config.workDirs.first, homeDir)
		
		// test 1 os path
		config = makeFpmConfig("C:\\Projects", [:])
		verifyEq(config.workDirs.size, 2)
		verifyEq(config.workDirs[0], `file:/C:/Projects/`.toFile)
		verifyEq(config.workDirs[1], homeDir)

		// test 2 os path
		config = makeFpmConfig("C:\\Projects;C:\\Temp", [:])
		verifyEq(config.workDirs.size, 3)
		verifyEq(config.workDirs[0], `file:/C:/Projects/`.toFile)
		verifyEq(config.workDirs[1], `file:/C:/Temp/`.toFile)
		verifyEq(config.workDirs[2], homeDir)

		// test props trump workDir
		config = makeFpmConfig("C:\\Projects", ["workDirs":"C:\\Temp"])
		verifyEq(config.workDirs.size, 3)
		verifyEq(config.workDirs[0], `file:/C:/Temp/`.toFile)
		verifyEq(config.workDirs[1], `file:/C:/Projects/`.toFile)
		verifyEq(config.workDirs[2], homeDir)

		// test uri path
		config = makeFpmConfig("file:/C:/Projects/", [:])
		verifyEq(config.workDirs.size, 2)
		verifyEq(config.workDirs[0], `file:/C:/Projects/`.toFile)
		verifyEq(config.workDirs[1], homeDir)

		// FIXME should we Err if a work dir doesn't exist? Or let it slide?
		// iF we err, we need to be able to print out all other config to resolve the problem
		// probably have a field: Str[] configErrs
		
		// test workDir not exist
//		verifyErr(ArgErr#) {
//			config = makeFpmConfig("wotever/", [:])
//		}
	}
	
	Void testRepoDirs() {
		homeDir := Env.cur.homeDir
		
		// test default
		config := makeFpmConfig(null, [:])
		verifyEq(config.fileRepos.size, 1)
		verifyEq(config.fileRepos["default"], homeDir + `fpmRepo-default/`)

		// test props add to fileRepos
		config = makeFpmConfig(null, ["fileRepo.release":"C:\\Projects"])
		verifyEq(config.fileRepos.size, 2)
		verifyEq(config.fileRepos["default"], homeDir + `fpmRepo-default/`)		
		verifyEq(config.fileRepos["release"], `file:/C:/Projects/`.toFile)

		// test props trump fileRepos
		config = makeFpmConfig(null, ["fileRepo.release":"C:\\Projects", "fileRepo.default":"C:\\Temp"])
		verifyEq(config.fileRepos.size, 2)
		verifyEq(config.fileRepos["default"], `file:/C:/Temp/`.toFile)
		verifyEq(config.fileRepos["release"], `file:/C:/Projects/`.toFile)

		// test uri path
		config = makeFpmConfig(null, ["fileRepo.default":"file:/C:/Projects/"])
		verifyEq(config.fileRepos.size, 1)
		verifyEq(config.fileRepos["default"], `file:/C:/Projects/`.toFile)

		// FIXME log non-existant dirs - see above
		
		// test fileRepo not exist
//		verifyErr(ArgErr#) {
//			config = makeFpmConfig(null, ["fileRepo.wot":"ever/"])
//		}
	}

	Void testPodDirs() {
		homeDir := Env.cur.homeDir
		
		// test default
		config := makeFpmConfig(null, [:])
		verifyEq(config.podDirs.size, 0)

		// test 1 pod dir
		config = makeFpmConfig(null, ["podDirs":"C:\\Projects"])
		verifyEq(config.podDirs.size, 1)
		verifyEq(config.podDirs[0], `file:/C:/Projects/`.toFile)

		// test 2 pod dirs
		config = makeFpmConfig(null, ["podDirs":"C:\\Projects;C:\\Temp"])
		verifyEq(config.podDirs.size, 2)
		verifyEq(config.podDirs[0], `file:/C:/Projects/`.toFile)
		verifyEq(config.podDirs[1], `file:/C:/Temp/`.toFile)

		// test uri path
		config = makeFpmConfig(null, ["podDirs":"file:/C:/Projects/"])
		verifyEq(config.podDirs.size, 1)
		verifyEq(config.podDirs[0], `file:/C:/Projects/`.toFile)

		// test relative path
		config = makeFpmConfig(null, ["podDirs":"fan/"])
		verifyEq(config.podDirs.size, 1)
		verifyEq(config.podDirs[0], `file:/C:/Projects/Fantom-Factory/Fpm/fan/`.toFile)

		// FIXME log non-existant dirs - see above

		// test podDir not exist
//		verifyErr(ArgErr#) {
//			config = makeFpmConfig(null, ["podDirs":"wotever/"])
//		}
	}
	
	private FpmConfig makeFpmConfig(Str? envPaths, Str:Str fpmProps) {
		FpmConfig.makeInternal(File(``), Env.cur.homeDir, envPaths, fpmProps, File#.emptyList)
	}
}
