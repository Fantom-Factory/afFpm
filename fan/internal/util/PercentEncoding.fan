
class PercentEncoding {
	
	// TODO percent encoding
//    private String substring(int start, int end, int section)
//    {
//      if (!decoding) return str.substring(start, end);
//
//      StringBuilder buf = new StringBuilder(end-start);
//      dpos = start;
//      while (dpos < end)
//      {
//        int ch = nextChar(section);
//        if (nextCharWasEscaped && ch < delimEscMap.length && (delimEscMap[ch] & section) != 0)
//          buf.append('\\');
//        buf.append((char)ch);
//      }
//      return buf.toString();
//    }
//
//    private int nextChar(int section)
//    {
//      int c = nextOctet(section);
//      if (c < 0) return -1;
//      int c2, c3;
//      switch (c >> 4)
//      {
//        case 0: case 1: case 2: case 3: case 4: case 5: case 6: case 7:
//          /* 0xxxxxxx*/
//          return c;
//        case 12: case 13:
//          /* 110x xxxx   10xx xxxx*/
//          c2 = nextOctet(section);
//          if ((c2 & 0xC0) != 0x80)
//            throw err("Invalid UTF-8 encoding");
//          return ((c & 0x1F) << 6) | (c2 & 0x3F);
//        case 14:
//          /* 1110 xxxx  10xx xxxx  10xx xxxx */
//          c2 = nextOctet(section);
//          c3 = nextOctet(section);
//          if (((c2 & 0xC0) != 0x80) || ((c3 & 0xC0) != 0x80))
//            throw err("Invalid UTF-8 encoding");
//          return (((c & 0x0F) << 12) | ((c2 & 0x3F) << 6) | ((c3 & 0x3F) << 0));
//        default:
//          throw err("Invalid UTF-8 encoding");
//      }
//    }
//
//    private int nextOctet(int section)
//    {
//      int c = str.charAt(dpos++);
//
//      // if percent encoded applied to all sections except
//      // scheme which should never never use this method
//      if (c == '%')
//      {
//        nextCharWasEscaped = true;
//        return (hexNibble(str.charAt(dpos++)) << 4) | hexNibble(str.charAt(dpos++));
//      }
//      else
//      {
//        nextCharWasEscaped = false;
//      }
//
//      // + maps to space only in query
//      if (c == '+' && section == QUERY)
//        return ' ';
//
//      // verify character ok
//      if (c >= charMap.length || (charMap[c] & section) == 0)
//        throw err("Invalid char in " + toSection(section) + " at index " + (dpos-1));
//
//      // return character as is
//      return c;
//    }
//
//    static int charAtSafe(String s, int index)
//    {
//      if (index < s.length()) return s.charAt(index);
//      return 0;
//    }
//
//    boolean decoding;
//    int dpos;
//    boolean nextCharWasEscaped;
}
