
internal class Utils {
	
	static Bool dependFits(Depend dep1, Depend dep2) {
		if (dep1.name != dep2.name)
			return false
		
		// TODO match multi version dependencies, e.g. "afBedSheet 1.0.2, 1.1-1.4, 1.8+"
		if (dep1.size > 1 || dep2.size > 1)
			return false

		// fixme wot not VersionConstraint?
		
		// FIXME wot no Depend.isSimple(idx)? 
		// There is no simple, stoopid!
		// TODO afBedSheed 1.5 needs be expanded to afBedSheet 1.5.0.0-1.5
//		if (dep1.isPlus(0).not && dep1.isRange(0))
//			return (0..<dep2.size).toList.any { dep2.match(dep1.version(0)) } 

//		if (dep1.isPlus(0))
//			return (0..<dep2.size).toList.any { dep2.isPlus(it) && dep1.version(0) > dep2.version(it) }
			
		return false
	}

	** Dumps the output similar to the following:
	** 
	** pre>
	** Could not satisfy the following constraints:
	** 
	**     afPlastic (1.2, 1.3)
	**         afIoc@2.1 ------> afPlastic 1.2
	**         afBedSheet@1.5 -> afPlastic 1.4
	** 	
	**     afEfan (1.5, 1.2, 2.3)
	**         afIoc@2.1 ------> afEfan 1.2
	**         afBedSheet@1.5 -> afEfan 1.4
	** <pre
	static Str dumpUnresolved(UnresolvedPod[] unresolvedPods) {
		if (unresolvedPods.isEmpty) return ""

		output	:= "Could not satisfy the following constraints:\n"
		unresolvedPods.each |unresolvedPod| {
			output	+= unresolvedPod.dump
		}
		return output
	}
	
	static Str[]? splitQuotedStr(Str? str) {
		if (str?.trimToNull == null)	return null
		strings	 := Str[,]
		chars	 := Int[,]
		prev	 := (Int?) null
		inQuotes := false
		str.each |c| {
			if (c.isSpace && inQuotes.not) { 
				if (chars.isEmpty.not) {
					strings.add(Str.fromChars(chars))
					chars.clear
				}
			} else if (c == '"') {
				if (inQuotes.not)
					if (chars.isEmpty)
						inQuotes = true
					else
						chars.add(c)
				else {
					inQuotes = false
					strings.add(Str.fromChars(chars))
					chars.clear					
				}
				
			} else
				chars.add(c)

			prev = null
		}

		if (chars.isEmpty.not)
			strings.add(Str.fromChars(chars))

		return strings
	}
}
