
internal const mixin FileUtils {
	
	** Warning! The returned dir may not exist!
	** 
	** 'base' may be a file or a dir.
	static File? toAbsDir(Str dirPath, File? base) {
		dir := toDir(dirPath) as File
		if (dir.uri.isPathRel)
			// can't resolve against null
			dir = base == null ? null : base + dir.uri
		return dir?.normalize
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
	
	static File toFile(Str path) {
		path.startsWith("file:") && path.containsChar('\\').not ? File(path.toUri, true) : File.os(path)
	}

	static Str:Str readMetaProps(File file) {
		zip	:= Zip.read(file.in)
		try {
			File? 		entry
			[Str:Str]?	metaProps
			while (metaProps == null && (entry = zip.readNext) != null) {
				if (entry.uri == `/meta.props`)
					metaProps = entry.readProps
			}
			if (metaProps == null)
				throw IOErr("Could not find `/meta.props` in pod file: ${file.normalize.osPath}")

			return metaProps

		} finally {
			zip.close
		}	
	}
}
