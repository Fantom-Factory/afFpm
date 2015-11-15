
const class PodFile {
	const Str		name
	const Version	version
	const File		file
	
	new make(|This|in) { in(this) }

	override Str toStr() {
		"$name $version"
	}
}
