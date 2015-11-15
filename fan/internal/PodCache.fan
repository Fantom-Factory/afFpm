
class PodCache {
	
	File:PodMeta	pods	:= File:PodMeta[:]
	
	PodMeta get(File file) {
		pods.getOrAdd(file) { readFile(file) }
	}
	
	private PodMeta readFile(File file) {
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
			return PodMeta(file, metaProps)

		} finally {
			zip.close
		}	
	}
}
