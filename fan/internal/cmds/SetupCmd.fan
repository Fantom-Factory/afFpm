using util

** installs 'fpm.bat' overwrites 'fan.bat'
** installs non-sys pods from %FAN_HOME% to local fanr repo
** installs non-sys pods from %PATH_ENV% to local fanr repo
** sets up etc/afFpm/config.props with repo loc and path env
internal class SetupCmd : FpmCmd {

	@Opt { aliases=["r"]; help="Name of the repository to publish to" }
	Str repo	:= "default"

	override Void go() {
		win := Env.cur.os.startsWith("win")

		log.indent("Running Setup...") |->| {

			log.info("\nCurrent Configuration")
			log.info("---------------------")
			log.info(fpmConfig.dump)

//			log.info("Setup will now copy pods into the repository named 'default'")
//			Env.cur.prompt("Is this correct? ")
			ext 		:= win ? ".bat" : ""
			fanFile		:= fpmConfig.homeDir + `bin/fan${ext}`
			fanResFile	:= typeof.pod.file(`/res/fan${ext}`)
			fanOrigFile	:= fpmConfig.homeDir + `bin/fan-orig${ext}`
			if (fanOrigFile.exists.not) {
				log.info("Renaming `${fanFile.osPath}` to `${fanOrigFile.name}`")
				fanFile.rename(fanOrigFile.name)
				log.info("Creating new `${fanFile.osPath}`")
				fanResFile.copyTo(fanFile)
				log.info("")
			}

			fpmFile		:= fpmConfig.homeDir + `bin/fpm${ext}`
			fpmResFile	:= typeof.pod.file(`/res/fpm${ext}`)
			if (fpmFile.exists.not) {
				log.info("Creating `${fpmFile.osPath}`")
				fpmResFile.copyTo(fpmFile)				
				log.info("")
			}

			configFile		:= fpmConfig.workDirs.first + `etc/afFpm/config.props`
			configResFile	:= typeof.pod.file(`/res/config.props`)
			if (configFile.exists.not) {
				log.info("Creating `${configFile.osPath}`")
				configResFile.copyTo(configFile)
				log.info("")
			}

			fpmConfig.workDirs.each {
				podManager.publishAllPods(it.plus(`lib/fan/`), repo)
				log.info("")
			}

			fpmConfig.podDirs.each {
				podManager.publishAllPods(it, repo)
				log.info("")
			}
			
			log.indent("To complete installation the following environment variable needs to be set:\n") |->| {
				if (win)
					log.info("set FAN_ENV=afFpm::FpmEnv")
				else
					log.info("export FAN_ENV=afFpm::FpmEnv")
			}
		}
		log.info("\nDone.\n")
	}
	
	override Bool argsValid() { true }
}
