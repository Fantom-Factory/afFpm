
internal const mixin FileUtils {
	
	** Warning! Dir may not exist!
	static File toAbsDir(Str dirPath, File baseDir := Env.cur.homeDir) {
		dir := toDir(dirPath)
		if (dir.uri.isPathAbs.not)
			dir = baseDir + dir.uri
		return dir.normalize
	}
	
	static File toFile(Str path) {
		path.startsWith("file:") && path.containsChar('\\').not ? File(path.toUri, true) : File.os(path)
	}

	private static File toDir(Str dirPath) {
		file := toFile(dirPath)
		// trailing slashes aren't added to dir paths that don't exist
		if (file.exists.not)
			file = file.uri.plusSlash.toFile
		if (file.isDir.not)
			throw ArgErr("Path is not a directory: ${dirPath} (${file.normalize.osPath})")
		return file
	}
}
