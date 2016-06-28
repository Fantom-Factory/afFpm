
@NoDoc
const class FpmEnvF4 : FpmEnv {
	const Str		name
	const Version	version
	const Depend[]	depends
	

	static new make(FpmConfig fpmConfig, |This| in) {
		try {
			if (Env.cur.vars["FPM_DEBUG"]?.trimToNull == "true")
				Log.get("afFpm").level = LogLevel.debug

			return FpmEnvF4.makeInternal(fpmConfig, in)
			
		} catch (Err e) {
			// this is really just belts and braces for FPM development as
			// otherwise we don't get a useful stack trace
			Env.cur.err.print(e.traceToStr)
			throw e
		}
	}

	private new makeInternal(FpmConfig fpmConfig, |This| in) : super.makeManual(fpmConfig, File#.emptyList, in) { }

	override internal Void findTarget(PodDependencies podDepends) {
		podDepends.setBuildTarget(name, version, depends, true)
	}
}
