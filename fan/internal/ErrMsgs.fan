
internal mixin ErrMsgs {
	
	static Str env_couldNotResolvePod(Depend depends) {
		"Could not resolve pod: ${depends}"
	}

	static Str mgr_podFileNotFound(File file) {
		"File not found: ${file.normalize.osPath}"
	}

	static Str mgr_podFileIsDir(File file) {
		"Pod file is directory: ${file.normalize.osPath}"
	}

	static Str mgr_podDirIsFile(File file) {
		"directory is a file: ${file.normalize.osPath}"
	}
}
