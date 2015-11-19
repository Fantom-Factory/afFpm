
** installs 'fpm.bat' overwrites 'fan.bat'
** installs non-sys pods from %FAN_HOME% to local fanr repo
** installs non-sys pods from %PATH_ENV% to local fanr repo
** sets up etc/afFpm/config.props with repo loc and path env
class SetupCmd : FpmCmd {

	override Int run() {

		// todo: do path env too
		PublishCmd(Env.cur.homeDir.plus(`lib/fan/`)).go
		
		return 0
	}
	
}
