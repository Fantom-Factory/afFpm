
internal class ArgParser {
	
	Obj parse(Str[] args, Type cmdType) {
		
		boolOpts	:= Field:Str[][:]
		strOpts		:= Field:Str[][:]
		argFields	:= Field[,]
		argsField	:= Str[,]
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
			if (field.hasFacet(Arg#))
				argFields.add(field)
		}
		
		consume := null as Field
		args.each |arg| {
			match := null
			
			if (match == null)
				if (consume != null) {
					ctorData[consume] = arg
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
					argsField.add(arg)
				else {
					field := argFields.removeAt(0)
					ctorData[field] = arg
				}
			}
		}
		
		ctorData[cmdType.field("args")] = argsField
		
		return cmdType.make([Field.makeSetFunc(ctorData)])
	}
}
