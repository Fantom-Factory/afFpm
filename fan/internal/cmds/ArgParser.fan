
internal class ArgParser {
	
	Str:|Field,Str->Obj?| resolveFns	:= Str:|Field,Str->Obj?|[:]
	
	Field:Obj? parse(Str[] args, Type cmdType) {
		
		boolOpts	:= Field:Str[][:]
		strOpts		:= Field:Str[][:]
		argFields	:= Field[,]
		argsField	:= null as Field
		argsData	:= Str[,]
		ctorData	:= Field:Obj?[:]
		
		cmdType.fields.each |field| {
			if (field.hasFacet(Opt#) && field.type.fits(Bool#)) {
				opt := (Opt) field.facet(Opt#)
				boolOpts[field] = ["--$field.name"].addAll( opt.aliases.map { "-$it" } )
			}
			if (field.hasFacet(Opt#) && !field.type.fits(Bool#)) {
				opt := (Opt) field.facet(Opt#)
				strOpts[field] = ["--$field.name"].addAll( opt.aliases.map { "-$it" } )
			}
			if (field.hasFacet(Arg#)) {
				if (field.type.fits(Str[]#))
					argsField = field
				else
					argFields.add(field)
			}
		}
		
		coerceVal := |Field field, Str arg -> Obj?| {
			if (resolveFns.containsKey(field.name))
				return resolveFns[field.name](field, arg)
			method := field.parent.method("parse${field.name.capitalize}", false)
			if (method != null && method.isStatic)
				return method.call(arg)
			if (field.type.fits(Str#))
				return arg
			return field.type.method("fromStr").call(arg)
		}
		
		consume := null as Field
		args.each |arg| {
			match := null
			
			if (match == null)
				if (consume != null) {
					ctorData[consume] = coerceVal(consume, arg)
					consume = null
					match = true
				}

			if (match == null)
				match = boolOpts.find |val, field| {
					if (val.any |opt| { opt == arg }) {
						ctorData[field] = true
						return true
					}
					return false
				}

			if (match == null)
				match = strOpts.find |val, field| {
					if (val.any |opt| { opt == arg }) {
						consume = field
						return true
					}
					return false
				}

			if (match == null) {
				if (argFields.isEmpty)
					argsData.add(arg)
				else {
					field := argFields.removeAt(0)
					ctorData[field] = coerceVal(field, arg)
				}
			}
		}
		
		if (argsField != null)
			ctorData[argsField] = argsData.toImmutable
		
		return ctorData
	}
}

internal facet class Arg {
	** Usage help, should be a single short line summary
	const Str help := ""
}

internal facet class Opt {
	** Usage help, should be a single short line summary
	const Str help := ""
	
	** Aliases for the option
	const Str[] aliases := Str[,]
}
