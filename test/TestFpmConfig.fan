
internal class TestFpmConfig : Test {
	
	Void testWorkDirs() {
		homeDir := Env.cur.homeDir
		
		// test default
		config := FpmConfig.makeInternal(File(``), homeDir, null, [:])
		verifyEq(config.workDirs.size, 1)
		verifyEq(config.workDirs.first, homeDir)

		// test default 2
		config = FpmConfig.makeInternal(File(``), homeDir, "", [:])
		verifyEq(config.workDirs.size, 1)
		verifyEq(config.workDirs.first, homeDir)
		
		// test 1 os path
		config = FpmConfig.makeInternal(File(``), homeDir, "C:\\Projects", [:])
		verifyEq(config.workDirs.size, 2)
		verifyEq(config.workDirs[0], `file:/C:/Projects/`.toFile)
		verifyEq(config.workDirs[1], homeDir)

		// test 2 os path
		config = FpmConfig.makeInternal(File(``), homeDir, "C:\\Projects;C:\\Temp", [:])
		verifyEq(config.workDirs.size, 3)
		verifyEq(config.workDirs[0], `file:/C:/Projects/`.toFile)
		verifyEq(config.workDirs[1], `file:/C:/Temp/`.toFile)
		verifyEq(config.workDirs[2], homeDir)

		// test props trump workDir
		config = FpmConfig.makeInternal(File(``), homeDir, "C:\\Projects", ["workDirs":"C:\\Temp"])
		verifyEq(config.workDirs.size, 3)
		verifyEq(config.workDirs[0], `file:/C:/Temp/`.toFile)
		verifyEq(config.workDirs[1], `file:/C:/Projects/`.toFile)
		verifyEq(config.workDirs[2], homeDir)

		// test uri path
		config = FpmConfig.makeInternal(File(``), homeDir, "file:/C:/Projects/", [:])
		verifyEq(config.workDirs.size, 2)
		verifyEq(config.workDirs[0], `file:/C:/Projects/`.toFile)
		verifyEq(config.workDirs[1], homeDir)

		// test workDir not exist
		verifyErr(ArgErr#) {
			config = FpmConfig.makeInternal(File(``), homeDir, "wotever/", [:])
		}
	}
	
	Void testRepoDirs() {
		homeDir := Env.cur.homeDir
		
		// test default
		config := FpmConfig.makeInternal(File(``), homeDir, null, [:])
		verifyEq(config.repoDirs.size, 1)
		verifyEq(config.repoDirs["default"], homeDir + `repo/`)

		// test props add to repoDirs
		config = FpmConfig.makeInternal(File(``), homeDir, null, ["repoDir.release":"C:\\Projects"])
		verifyEq(config.repoDirs.size, 2)
		verifyEq(config.repoDirs["default"], homeDir + `repo/`)		
		verifyEq(config.repoDirs["release"], `file:/C:/Projects/`.toFile)

		// test props trump repoDirs
		config = FpmConfig.makeInternal(File(``), homeDir, null, ["repoDir.release":"C:\\Projects", "repoDir.default":"C:\\Temp"])
		verifyEq(config.repoDirs.size, 2)
		verifyEq(config.repoDirs["default"], `file:/C:/Temp/`.toFile)
		verifyEq(config.repoDirs["release"], `file:/C:/Projects/`.toFile)

		// test uri path
		config = FpmConfig.makeInternal(File(``), homeDir, null, ["repoDir.default":"file:/C:/Projects/"])
		verifyEq(config.repoDirs.size, 1)
		verifyEq(config.repoDirs["default"], `file:/C:/Projects/`.toFile)

		// test repoDir not exist
		verifyErr(ArgErr#) {
			config = FpmConfig.makeInternal(File(``), homeDir, null, ["repoDir.wot":"ever/"])
		}
	}

	Void testPodDirs() {
		homeDir := Env.cur.homeDir
		
		// test default
		config := FpmConfig.makeInternal(File(``), homeDir, null, [:])
		verifyEq(config.podDirs.size, 0)

		// test 1 pod dir
		config = FpmConfig.makeInternal(File(``), homeDir, null, ["podDirs":"C:\\Projects"])
		verifyEq(config.podDirs.size, 1)
		verifyEq(config.podDirs[0], `file:/C:/Projects/`.toFile)

		// test 2 pod dirs
		config = FpmConfig.makeInternal(File(``), homeDir, null, ["podDirs":"C:\\Projects;C:\\Temp"])
		verifyEq(config.podDirs.size, 2)
		verifyEq(config.podDirs[0], `file:/C:/Projects/`.toFile)
		verifyEq(config.podDirs[1], `file:/C:/Temp/`.toFile)

		// test uri path
		config = FpmConfig.makeInternal(File(``), homeDir, null, ["podDirs":"file:/C:/Projects/"])
		verifyEq(config.podDirs.size, 1)
		verifyEq(config.podDirs[0], `file:/C:/Projects/`.toFile)

		// test relative path
		config = FpmConfig.makeInternal(File(``), homeDir, null, ["podDirs":"fan/"])
		verifyEq(config.podDirs.size, 1)
		verifyEq(config.podDirs[0], `file:/C:/Projects/Fantom-Factory/FantomPodManager/fan/`.toFile)

		// test podDir not exist
		verifyErr(ArgErr#) {
			config = FpmConfig.makeInternal(File(``), homeDir, null, ["podDirs":"wotever/"])
		}
	}
}
