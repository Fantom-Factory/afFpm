
internal class TestUtils :Test {
	
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
