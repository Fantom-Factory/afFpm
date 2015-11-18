
const class PodFile {
	const Str		name
	const Version	version
	const File		file
	
	internal new make(|This|in) { in(this) }

	
	static new makeFromFile(File file) {
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
			return PodVersion(file, metaProps).toPodFile

		} finally {
			zip.close
		}	
	}

	override Str toStr() {
		"$name $version"
	}
}
