
mixin Resolver {
	
	abstract PodFile[] resolve()
}

class LocalResolver : Resolver {

	new make(|This| f) { f(this) }

	override PodFile[] resolve() { throw UnsupportedErr() }
}

class QueryResolver : Resolver {
	
	new make(|This| f) { f(this) }

	// the hard bit
	override PodFile[] resolve() { throw UnsupportedErr() }
}

class BuildResolver : Resolver {
	
	new make(|This| f) { f(this) }
	
	// the hard bit
	override PodFile[] resolve() { throw UnsupportedErr() }
}