
internal class TestUtils :Test {
	
	Void testDependFits() {
//		afBedSheet 1.0.2, 1.1-1.4, 1.8+
		
		verifyDependsNot("afBedSheet 1.0", "afIoc 1.0")
		verifyDependsNot("afBedSheet 1.0", "afBedSheet 2.0")

		verifyDepends	("afBedSheet 1", "afBedSheet 1")
		verifyDepends	("afBedSheet 1", "afBedSheet 1.0")
		verifyDepends	("afBedSheet 1", "afBedSheet 1.0.0")
		verifyDepends	("afBedSheet 1", "afBedSheet 1.0.0.0")

		verifyDepends	("afBedSheet 1", "afBedSheet 1.0 - 1.1")
	}
	
	Void verifyDepends(Str d1, Str d2) {
		verifyTrue(Utils.dependFits(Depend(d1), Depend(d2)))
	}
	
	Void verifyDependsNot(Str d1, Str d2) {
		verifyFalse(Utils.dependFits(Depend(d1), Depend(d2)))
	}
	
	Void testSplitQuotedStr() {
		verifyEq(Utils.splitQuotedStr(null), null)
		verifyEq(Utils.splitQuotedStr(""), null)
		
		// standard split
		verifyEq(Utils.splitQuotedStr("how are you"), Str["how", "are", "you"])

		// standard split - moar spaces
		verifyEq(Utils.splitQuotedStr("   how   are   you   "), Str["how", "are", "you"])
		
		// standard quotes
		verifyEq(Utils.splitQuotedStr("\"how are you\""), Str["how are you"])
		
		// mixed
		verifyEq(Utils.splitQuotedStr("\"how are\" you"), Str["how are", "you"])
		
		// no closing quote
		verifyEq(Utils.splitQuotedStr("how \"are you"), Str["how", "are you"])
		
		// quotes not prefixed with space
		verifyEq(Utils.splitQuotedStr("how\"are\" you"), Str["how\"are\"", "you"])

		// quotes surrounded with space
		verifyEq(Utils.splitQuotedStr("how \" are \" you"), Str["how", " are ", "you"])

		// quotes surrounded with space
		verifyEq(Utils.splitQuotedStr("how \" are \"you"), Str["how", " are ", "you"])

		// quotes surrounded with space
		verifyEq(Utils.splitQuotedStr("how \" are y\"ou"), Str["how", " are y", "ou"])
	}
}
