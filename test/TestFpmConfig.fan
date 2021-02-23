
internal class TestFpmConfig : Test {
	
	Void testWorkDirs() {
		homeDir := Env.cur.homeDir
		config	:= null as FpmConfig
		
		// test default
		config = makeFpmConfigFromFanEnvPath(null)
		verifyEq(config.workDirs.size, 1)
		verifyEq(config.workDirs.first, homeDir)

		// test default 2
		config = makeFpmConfigFromFanEnvPath("")
		verifyEq(config.workDirs.size, 1)
		verifyEq(config.workDirs.first, homeDir)
		
		// test 1 os path
		config = makeFpmConfigFromFanEnvPath("C:\\Projects")
		verifyEq(config.workDirs.size, 2)
		verifyEq(config.workDirs[0], `file:/C:/Projects/`.toFile)
		verifyEq(config.workDirs[1], homeDir)

		// test 2 os path
		config = makeFpmConfigFromFanEnvPath("C:\\Projects;C:\\Temp")
		verifyEq(config.workDirs.size, 3)
		verifyEq(config.workDirs[0], `file:/C:/Projects/`.toFile)
		verifyEq(config.workDirs[1], `file:/C:/Temp/`.toFile)
		verifyEq(config.workDirs[2], homeDir)

		// test props trump workDir
		config = makeFpmConfigFromFanEnvPath("C:\\Projects", ["workDirs":"C:\\Temp"])
		verifyEq(config.workDirs.size, 3)
		verifyEq(config.workDirs[0], `file:/C:/Temp/`.toFile)
		verifyEq(config.workDirs[1], `file:/C:/Projects/`.toFile)
		verifyEq(config.workDirs[2], homeDir)

		// test uri path
		config = makeFpmConfigFromFanEnvPath("file:/C:/Projects/")
		verifyEq(config.workDirs.size, 2)
		verifyEq(config.workDirs[0], `file:/C:/Projects/`.toFile)
		verifyEq(config.workDirs[1], homeDir)
	}

	Void testFanrRepos() {
		homeDir := Env.cur.homeDir
		
		// test default
		config := makeFpmConfigFromProps([:])
		verifyEq(config.fanrRepos.size, 0)

		// test that a default is added
		config = makeFpmConfigFromProps(["fanrRepo.release":"C:\\Projects"])
		verifyEq(config.fanrRepos.size, 1)
		verifyEq(config.fanrRepos["release"], `file:/C:/Projects/`)

		// test defined default trumps the auto default
		config = makeFpmConfigFromProps(["fanrRepo.release":"C:\\Projects", "fanrRepo.default":"C:\\Temp"])
		verifyEq(config.fanrRepos.size, 2)
		verifyEq(config.fanrRepos["default"], `file:/C:/Temp/`)
		verifyEq(config.fanrRepos["release"], `file:/C:/Projects/`)
		verifyEq(config.dirRepos["default"], null)	// test we've overridden it with a fanr repo

		// test repo removal
		config = makeFpmConfigFromProps(["fanrRepo.killme":"", "fanrRepo.temp":"C:\\Temp"])
		verifyEq(config.fanrRepos.size, 1)
		verifyEq(config.fanrRepos["temp"], `file:/C:/Temp/`)

		// test uri path
		config = makeFpmConfigFromProps(["fanrRepo.default":"file:/C:/Projects/"])
		verifyEq(config.fanrRepos.size, 1)
		verifyEq(config.fanrRepos["default"], `file:/C:/Projects/`)

		// test rel path
		// if people want it relative to FAN_HOME, add a ${fanHome} str replace macro
		config = makeFpmConfigFromProps(["fanrRepo.default":"/repo"])
		verifyEq(config.fanrRepos.size, 1)
		verifyEq(config.fanrRepos["default"], `file:/C:/repo/`.toFile.normalize.uri)
	}

	Void testDirRepos() {
		homeDir := Env.cur.homeDir

		// test default & fanHome
		config := makeFpmConfigFromProps([:])
		verifyEq(config.dirRepos.size, 2)
		verifyEq(config.dirRepos["fanHome"], homeDir + `lib/fan/`)
		verifyEq(config.dirRepos["default"], homeDir + `lib/fan/`)

		// test default & fanHome can be overriddden
		config = makeFpmConfigFromProps(["dirRepo.fanHome":"C:\\Projects", "dirRepo.default":"C:\\Temp"])
		verifyEq(config.dirRepos.size, 2)
		verifyEq(config.dirRepos["default"], `file:/C:/Temp/`.toFile)
		verifyEq(config.dirRepos["fanHome"], `file:/C:/Projects/`.toFile)

		// test repo removal
		config = makeFpmConfigFromProps(["dirRepo.killme":"", "dirRepo.temp":"C:\\Temp"])
		verifyEq(config.dirRepos.size, 3)
		verifyEq(config.dirRepos["temp"], `file:/C:/Temp/`.toFile)
		verifyEq(config.dirRepos["fanHome"], homeDir + `lib/fan/`)
		verifyEq(config.dirRepos["default"], homeDir + `lib/fan/`)

		// test rel path
		config = makeFpmConfigFromProps(["dirRepo.default":"/repo"])
		verifyEq(config.dirRepos.size, 2)
		verifyEq(config.dirRepos["fanHome"], homeDir + `lib/fan/`)
		verifyEq(config.dirRepos["default"], `file:/C:/repo/`.toFile.normalize)

		// test workDirs
		config = makeFpmConfigFromProps(["workDirs":"C:\\Temp"])
		verifyEq(config.dirRepos.size, 3)
		verifyEq(config.dirRepos["fanHome"], homeDir + `lib/fan/`)
		verifyEq(config.dirRepos["default"], homeDir + `lib/fan/`)
		verifyEq(config.dirRepos["workDir"], `file:/C:/Temp/lib/fan/`.toFile)

		// test workDirs x 2
		config = makeFpmConfigFromProps(["workDirs":"C:\\Temp;C:\\Temp2"])
		verifyEq(config.dirRepos.size, 4)
		verifyEq(config.dirRepos["fanHome"], homeDir + `lib/fan/`)
		verifyEq(config.dirRepos["default"], homeDir + `lib/fan/`)
		verifyEq(config.dirRepos["workDir"], `file:/C:/Temp/lib/fan/`.toFile)
		verifyEq(config.dirRepos["workDir[1]"], `file:/C:/Temp2/lib/fan/`.toFile)

		// if people want it relative to FAN_HOME, add a ${fanHome} str replace macro
		config = makeFpmConfigFromProps(["dirRepo.default":"\${fanHome}/repo", "workDirs":"\${fanHome}/work/"])
		verifyEq(config.dirRepos.size, 3)
		verifyEq(config.dirRepos["fanHome"], homeDir + `lib/fan/`)
		verifyEq(config.dirRepos["default"], homeDir + `repo/`)
		verifyEq(config.dirRepos["workDir"], homeDir + `work/lib/fan/`)

		// again, but without a trailing slash
		config = makeFpmConfigFromProps(["dirRepo.default":"\${fanHome}/repo", "workDirs":"\${fanHome}/work"])
		verifyEq(config.dirRepos.size, 3)
		verifyEq(config.dirRepos["default"], homeDir + `repo/`)

		// not sure if the extra processing effort is worth it - see todo comment in FpmConfig
//		// ${workDir} str replace macro for fanr repos
//		config = makeFpmConfigFromProps(["fanrRepo.default":"\${workDir}/repo-def", "workDirs":"\${fanHome}/work/"])
//		verifyEq(config.dirRepos.size, 2)
//		verifyEq(config.dirRepos["fanHome"], homeDir + `lib/fan/`)
//		verifyEq(config.dirRepos["workDir"], homeDir + `work/lib/fan/`)
//		verifyEq(config.fanrRepos.size, 1)
//		verifyEq(config.fanrRepos["default"], (homeDir + `work/repo-def/`).uri)
	}

	Void testRawConfigRemovesCreds() {
		config := makeFpmConfigFromProps([
			"fanrRepo.eggbox"   		: "http://user:pass@eggbox.fantomfactory.org/fanr/",
		])

		verifyEq(config.fanrRepos["eggbox"], `http://eggbox.fantomfactory.org/fanr/`)
		verifyEq(config.props["fanrRepo.eggbox.username"], "user")
		verifyEq(config.props["fanrRepo.eggbox.password"], "pass")
		verifyEq(config.props["fanrRepo.eggbox"], "http://eggbox.fantomfactory.org/fanr/")
	}
	
	Void testBadConfigDupRepoName() {
		verifyErrMsg(Err#, "Repository 'eggbox' is defined as both a dirRepo AND a fanrRepo") {
			makeFpmConfigFromProps([
				"fanrRepo.eggbox"   : "http://eggbox.fantomfactory.org/fanr/",
				"dirRepo.eggbox"	: "eggbox",
			])
		}
	}
	
	private FpmConfig makeFpmConfigFromFanEnvPath(Str? fanEnvPath, [Str:Str]? props := null) {
		FpmConfig(RawProps(props ?: [:], null), `./`.toFile, Env.cur.homeDir, fanEnvPath)
	}

	private FpmConfig makeFpmConfigFromProps(Str:Str fpmProps) {
		FpmConfig(RawProps(fpmProps, null), `./`.toFile, Env.cur.homeDir, null)
	}
}
