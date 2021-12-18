
internal const class CorePods {
	private static const Str[]	corePodNames	:= "asn1 build compiler compilerDoc compilerJava compilerJs concurrent crypto cryptoJava docDomkit docFanr docIntro docLang docTools dom domkit email fandoc fanr fansh flux fluxText fwt gfx graphics icons inet math obix sql syntax sys testCompiler testDomkit testJava testNative util web webfwt webmod wisp xml".split

	static const CorePods instance := CorePods.makePrivate()
	
	private new makePrivate() { }
	static new makeSingleton() { instance }
	
	Bool isCorePod(Str podName) {
		corePodNames.any { it.equalsIgnoreCase(podName) }
	}
}
