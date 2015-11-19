
internal class FileCache {
	
	File:PodVersion?	files	:= File:PodVersion?[:]
	
	PodVersion? get(File file) {
		files.getOrAdd(file) { readFile(file) }
	}
	
	static PodVersion? readFile(File file) {
		if (file.exists.not)
			return null

		zip	:= Zip.read(file.in)
		try {
			File? 		entry
			[Str:Str]?	metaProps
			while (metaProps == null && (entry = zip.readNext) != null) {
				if (entry.uri == `/meta.props`)
					metaProps = entry.readProps
			}
			if (metaProps == null)
				throw Err("Pod file ${file.normalize.osPath} does not contain `/meta.props`")
			return PodVersion(file, metaProps)

		} finally {
			zip.close
		}	
	}
}
