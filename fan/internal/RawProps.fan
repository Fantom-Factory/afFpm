
** 'RawProps' provides properties from an 'fpm.props' file, after performing a little pre-processing.
** Such as:
**  - splitting user info from fanrRepo URLs into '.username' and '.password' properties
**  - clearing properties from parent
**  - extracting any 'macro' properties
**  
@NoDoc
const class RawProps {

//	static const RawProps defVal := RawProps(Str:Str[:], null)
	static RawProps defVal() { RawProps(Str:Str[:], null) }
	
	** The chained parent props.
	const RawProps?	parent
	
	** The 'fpm.props' file this instance represents.
	const File?		file

	** Property keys that *this* 'fpm.props' file asks to be cleared from children. 
	const Str[]		clearKeys

	** Returns all macros found in this 'fpm.props' file.
	const Str:Str	macros

	** Properties found in *this* 'fpm.props' file, post cleaning operations.
	const Str:Str	props

//	static new make(Str:Str rawProps, RawProps? parent := null) {
//		file := Buf().writeProps(rawProps).toFile(`/temp/fpm.props`)
//		return RawProps.fromFile(file, parent)
//	}

	new fromFile(Str:Str rawProps, File? file, RawProps? parent := null) {
		file = file?.normalize
		if (file != null && (file.isDir || file.exists.not))
			throw ArgErr("Props file is not valid: ${file.osPath}")

		// find *our* clear keys - and remove from props
		clearKeys	:= Str[,]
		rawProps.each |value, name| {
			if (name.startsWith("clear.") && value == "true")
				clearKeys.add(name["clear.".size..-1])
		}
		clearKeys.each |key| { rawProps.remove("clear.${key}") }
		
		// split out user info from fanrRepo URLs into '.username' and '.password' properties
		rawProps.keys.findAll |key| {
			key.startsWith("fanrRepo.") && !key.endsWith(".username") && !key.endsWith(".password")
		}.each |key| {
			path := rawProps[key].trimToNull
			if (path == null) return		// empty string may be removing config

			name := key["fanrRepo.".size..-1]
			url  := Uri(path, false)

			if (url?.userInfo != null) {
				userInfo := url.userInfo.split(':')
				repoName := key["fanrRepo.".size..-1]
				userkey	 := "fanrRepo.${repoName}.username"
				passkey	 := "fanrRepo.${repoName}.password"
				username := Uri.decodeToken(userInfo.getSafe(0) ?: "", Uri.sectionPath).trimToNull
				password := Uri.decodeToken(userInfo.getSafe(1) ?: "", Uri.sectionPath).trimToNull
				
				// don't override existing explicit config - I think .password should override userinfo
				if (username != null && !rawProps.containsKey(userkey))
					rawProps[userkey] = username
				if (username != null && !rawProps.containsKey(passkey))
					rawProps[passkey] = password

				// remove the userinfo from the repo URL
				rawProps[key] = path.replace("${url.userInfo}@", "")
			}
		}
		
		// do as our parent demands and clear what it doesn't like
		keysToClear := parent?.clearKeys
		if (keysToClear != null) {
			if (keysToClear.contains("all")) {
				rawProps.clear
				keysToClear = keysToClear.rw
				keysToClear.remove("all")
			}
			rawProps.keys.each |key| {
				keysToClear.each |toClear| {
					if (key == toClear || key.startsWith(toClear + "."))
						rawProps.remove(key)
				}
			}
		}
		
		// find macros
		macros	:= Str:Str[:] { it.ordered = true }
		rawProps.keys.each |key| {
			if (key.startsWith("macro.")) {
				macros[key["macro.".size..-1]] = rawProps[key]
				rawProps.remove(key)
			}
		}

		this.parent		= parent
		this.file		= file
		this.clearKeys	= clearKeys
		this.macros		= macros
		this.props		= rawProps
	}
	
	** Returns all resolved properties from this file and any parent file.
	Str:Str allProps() {
		allProps := parent?.allProps ?: Str:Str[:] { it.ordered = true }	
		allProps.setAll(this.props)
		return allProps
	}

	** Returns all resolved macros found in this file and any parent files.
	** 
	** Values with empty strings are preserved.
	Str:Str	allMacros() {
		allProps := parent?.allMacros ?: Str:Str[:] { it.ordered = true }	
		allProps.setAll(this.macros)
		// keep empty string values
		return allProps
	}

	** Converts the given path to a directory, relative to the 'fpm.props' file that defines it.
	File? toRelDir(Str key, Str? pathValue) {
		if (pathValue == null) return null
		return props.containsKey(key)
			? FileUtils.toAbsDir(pathValue, file)
			: parent?.toRelDir(key, pathValue)
	}

	** A list of all 'fpm.props' files this instance wraps. 
	File[] files() {
		files := this.parent?.files ?: File[,]
		if (file != null)
			files.add(file)
		return files
	}
}
