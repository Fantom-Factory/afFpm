
** 'RawProps' provides properties from an 'fpm.props' file, after performing a little pre-processing.
** Such as:
**  - extracting any 'macro' properties
**  - splitting user info from fanrRepo URLs into '.username' and '.password' properties
**  
const class RawProps {
	
	** The 'fpm.props' file this instance represents.
	const File		file

	** The raw properties contained within the 'fpm.props'.
	const Str:Str	props

	** The macros found in 'fpm.props'.
	const Str:Str	macros

	new make(File propsFile) {
		propsFile = propsFile.normalize
		if (propsFile.isDir || propsFile.exists.not)
			throw ArgErr("Props file is not valid: ${propsFile.osPath}")

		props	:= propsFile.readProps
		macros	:= Str:Str[:] { it.ordered = true }
		props.each |value, name| {
			if (name.startsWith("macro."))
				macros[name["macro.".size..-1]] = value
		}

		// split out user info from fanrRepo URLs into '.username' and '.password' properties
		props.keys.findAll |key| {
			key.startsWith("fanrRepo.") && !key.endsWith(".username") && !key.endsWith(".password")
		}.each |key| {
			path := props[key].trimToNull
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
				if (username != null && !props.containsKey(userkey))
					props[userkey] = username
				if (username != null && !props.containsKey(passkey))
					props[passkey] = password

				// remove the userinfo from the repo URL
				props[key] = path.replace("${url.userInfo}@", "")
			}
		}
		
		this.file	= propsFile
		this.props	= props
		this.macros	= macros
	}
}
