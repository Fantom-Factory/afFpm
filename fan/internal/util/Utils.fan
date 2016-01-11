
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
}
