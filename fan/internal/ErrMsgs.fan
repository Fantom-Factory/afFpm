
internal mixin ErrMsgs {
	
	static Str env_couldNotResolvePod(Str depends) {
		"Could not resolve pod: ${depends}"
	}

	static Str mgr_podFileNotFound(File file) {
		"File not found: ${file.normalize.osPath}"
	}
}
