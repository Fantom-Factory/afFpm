
** In normal Base64 encoding, an Int of '0' is returned as 'AAAAAAAAAAE=' which is not quite what we want!
** http://tools.ietf.org/html/rfc4648#section-5
internal class Base64 {	
	private static const Str base64	:= "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_"
	
	static Str toBase64(Int int, Int pad := 1) {
		b64	:= ""

		while (int > 0) {
			rem := int % 64
			b64  = base64[rem].toChar + b64
			int  = int / 64
		}

		return b64.padl(pad, '0')
	}
	
	static Int fromBase64(Str b64) {
		while (b64.startsWith("0"))
			b64 = b64[1..-1]
		total := 0
		tens := 1
		b64.eachr |chr| {
			total = total + (base64.index(chr.toChar) * tens)
			tens = tens * 64
		}
		return total
	}	
}
