
internal class TestFpmEnvDefault :Test {
	
	Void testSplitQuotedStr() {
		verifyEq(FpmEnvDefault.splitQuotedStr(null), null)
		verifyEq(FpmEnvDefault.splitQuotedStr(""), null)
		
		// standard split
		verifyEq(FpmEnvDefault.splitQuotedStr("how are you"), Str["how", "are", "you"])

		// standard split - moar spaces
		verifyEq(FpmEnvDefault.splitQuotedStr("   how   are   you   "), Str["how", "are", "you"])
		
		// standard quotes
		verifyEq(FpmEnvDefault.splitQuotedStr("\"how are you\""), Str["how are you"])
		
		// mixed
		verifyEq(FpmEnvDefault.splitQuotedStr("\"how are\" you"), Str["how are", "you"])
		
		// no closing quote
		verifyEq(FpmEnvDefault.splitQuotedStr("how \"are you"), Str["how", "are you"])
		
		// quotes not prefixed with space
		verifyEq(FpmEnvDefault.splitQuotedStr("how\"are\" you"), Str["how\"are\"", "you"])

		// quotes surrounded with space
		verifyEq(FpmEnvDefault.splitQuotedStr("how \" are \" you"), Str["how", " are ", "you"])

		// quotes surrounded with space
		verifyEq(FpmEnvDefault.splitQuotedStr("how \" are \"you"), Str["how", " are ", "you"])

		// quotes surrounded with space
		verifyEq(FpmEnvDefault.splitQuotedStr("how \" are y\"ou"), Str["how", " are y", "ou"])
	}
}
