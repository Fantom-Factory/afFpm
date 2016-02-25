
internal const class FileUtils {

	static File toAbsDir(Str dirPath) {
		dir := toDir(dirPath).normalize
		if (dir.uri.isPathAbs.not)
			throw ArgErr("Directory path must be absolute: ${dirPath}")
		return dir
	}
	
	** Warning! Dir may not exist!
	static File toRelDir(File baseDir, Str dirPath) {
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
