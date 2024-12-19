
internal const class CorePods {
	// from Fantom 1.0.81
	private static const Str[]	corePodNames	:= "asn1 build compiler compilerDoc compilerEs compilerJava compilerJs concurrent crypto cryptoJava docDomkit docFanr docIntro docLang docTools dom domkit email fandoc fanr fansh flux fluxText fwt gfx graphics graphicsJava icons inet markdown math nodeJs sql syntax sys testCompiler testDomkit testJava testNative util web webfwt webmod wisp xml yaml".split
	
	static const CorePods instance := CorePods.makePrivate()
	
	private new makePrivate() { }
	static new makeSingleton() { instance }
	
	Bool isCorePod(Str podName) {
		corePodNames.any { it.equalsIgnoreCase(podName) }
	}
}
