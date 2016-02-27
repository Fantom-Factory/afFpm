using util

** installs 'fpm.bat' overwrites 'fan.bat'
** installs non-sys pods from %FAN_HOME% to local fanr repo
** installs non-sys pods from %PATH_ENV% to local fanr repo
** sets up etc/afFpm/config.props with repo loc and path env
@NoDoc
class SetupCmd : FpmCmd {

	private const CorePods	corePods	:= CorePods()

	@Opt { aliases=["r"]; help="Name of the repository to publish to" }
	Str repo	:= "default"

	override Int go() {
		win := Env.cur.os.startsWith("win")

//		log.indent("Running Setup...") |->| {

			log.info("\nCurrent Configuration")
			log.info("---------------------")
			log.info(fpmConfig.dump)

//			log.info("Setup will now copy pods into the repository named 'default'")
//			Env.cur.prompt("Is this correct? ")

			ext 		:= win ? ".bat" : ""
			fpmFile		:= fpmConfig.homeDir + `bin/fpm${ext}`
			fanResFile	:= typeof.pod.file(`/res/fpm${ext}`)
			if (fpmFile.exists.not) {
				log.info("Creating `${fpmFile.osPath}`")
				fanResFile.copyTo(fpmFile)
				log.info("")
			}
			
			if (!win) {
				try		Process(["chmod", "+x"], fpmFile.parent).run.join
				catch	log.warn("Could not set execute permissions on: ${fpmFile.osPath}")
			}

			configFile		:= fpmConfig.workDirs.first + `etc/afFpm/config.props`
			configResFile	:= typeof.pod.file(`/res/config.props`)
			if (configFile.exists.not) {
				log.info("Creating `${configFile.osPath}`")
				configResFile.copyTo(configFile)
				log.info("")
			}

			fpmConfig.workDirs.each {
				installAllPodsFromDir(it.plus(`lib/fan/`), repo)
				log.info("")
			}

			fpmConfig.podDirs.each {
				installAllPodsFromDir(it, repo)
				log.info("")
			}			
//		}
		log.info("\nDone.\n")
		return 0
	}
	
	override Bool argsValid() { true }
	
	** Publishes all pods from the given directory.
	**  
	** 'repo' should be the name of a local file repository, or a directory path.
	** Directory paths may be in URI form or an OS path.
	**  
	** 'repo' defaults to 'default' if not specified.
	private Void installAllPodsFromDir(File dir, Str? repo := null) {
		log.info("Publishing pods from ${dir.osPath} into repo '" +  (repo ?: "default") + "'...")
		podFiles := dir.listFiles(".+\\.pod".toRegex).exclude {
			corePods.isCorePod(it.basename) || it.basename == "afFpm"
		}
		if (podFiles.isEmpty)
			log.info("  No pods found")
		
		podFiles.each |file| {
			podManager.publishPod(file, repo)
		}
	}

}
