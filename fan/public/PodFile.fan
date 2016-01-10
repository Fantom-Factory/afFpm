
** Represents a pod file.
const class PodFile {
	** The name of this pod.
	const Str		name
	
	** The version of this pod.
	const Version	version
	
	** The backing file of this pod.
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

	override Str toStr() 			{ "$name $version" }
	override Int hash() 			{ file.hash }
	override Bool equals(Obj? that)	{ file == (that as PodFile)?.file }
}
