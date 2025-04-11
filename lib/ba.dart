class Ba {
  static String atob(List<int> a) {
    return _atob(a, false);
  }

  static String atoab(List<int> a) {
    return _atob(a, true);
  }

  static String _atob(List<int> a, bool alternate) {
    int aLen = a.length;
    int numFullGroups = (aLen / 3).toInt();
    int numBytesInPartialGroup = aLen - 3 * numFullGroups;
    int resultLen = (4 * ((aLen + 2) / 3)).toInt();
    var result = "";
    List<String> intToAlpha = (alternate ? _itoab_list : _itob_list);

    int inCursor = 0;
    for (int i = 0; i < numFullGroups; i++) {
      int byte0 = a[inCursor++] & 0xff;
      int byte1 = a[inCursor++] & 0xff;
      int byte2 = a[inCursor++] & 0xff;
      result += intToAlpha[byte0 >> 2];
      result += intToAlpha[(byte0 << 4) & 0x3f | (byte1 >> 4)];
      result += intToAlpha[(byte1 << 2) & 0x3f | (byte2 >> 6)];
      result += intToAlpha[byte2 & 0x3f];
    }

    if (numBytesInPartialGroup != 0) {
      int byte0 = a[inCursor++] & 0xff;
      result = result + intToAlpha[byte0 >> 2];
      if (numBytesInPartialGroup == 1) {
        result += intToAlpha[(byte0 << 4) & 0x3f];
        result += "==";
      } else {
        int byte1 = a[inCursor++] & 0xff;
        result += intToAlpha[(byte0 << 4) & 0x3f | (byte1 >> 4)];
        result += intToAlpha[(byte1 << 2) & 0x3f];
        result += "=";
      }
    }
    return result;
  }

  static const List<String> _itob_list = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
    'a',
    'b',
    'c',
    'd',
    'e',
    'f',
    'g',
    'h',
    'i',
    'j',
    'k',
    'l',
    'm',
    'n',
    'o',
    'p',
    'q',
    'r',
    's',
    't',
    'u',
    'v',
    'w',
    'x',
    'y',
    'z',
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '+',
    '/',
  ];

  static const List<String> _itoab_list = [
    '!',
    '"',
    '#',
    '\$',
    '%',
    '&',
    '\'',
    '(',
    ')',
    ',',
    '-',
    '.',
    ':',
    ';',
    '<',
    '>',
    '@',
    '[',
    ']',
    '^',
    '`',
    '_',
    '{',
    '|',
    '}',
    '~',
    'a',
    'b',
    'c',
    'd',
    'e',
    'f',
    'g',
    'h',
    'i',
    'j',
    'k',
    'l',
    'm',
    'n',
    'o',
    'p',
    'q',
    'r',
    's',
    't',
    'u',
    'v',
    'w',
    'x',
    'y',
    'z',
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '+',
    '?',
  ];

  static List<int> btoa(String s) {
    return _btoa(s, false);
  }

  static List<int> abtoa(String s) {
    return _btoa(s, true);
  }

  static List<int> _btoa(String s, bool alternate) {
    List<int> alphaToInt = (alternate ? _abtoi_list : _btoi_list);
    int sLen = s.length;
    int numGroups = (sLen / 4).toInt();
    if (4 * numGroups != sLen) {
      throw ArgumentError("String length must be a multiple of four.");
    }
    int missingBytesInLastGroup = 0;
    int numFullGroups = numGroups;
    if (sLen != 0) {
      if (s[sLen - 1] == "=") {
        missingBytesInLastGroup++;
        numFullGroups--;
      }
      if (s[sLen - 2] == '=') {
        missingBytesInLastGroup++;
      }
    }
    List<int> result = List.filled(3 * numGroups - missingBytesInLastGroup, 0);

    int inCursor = 0, outCursor = 0;
    for (int i = 0; i < numFullGroups; i++) {
      int ch0 = _btoi(s[inCursor++].codeUnitAt(0), alphaToInt);
      int ch1 = _btoi(s[inCursor++].codeUnitAt(0), alphaToInt);
      int ch2 = _btoi(s[inCursor++].codeUnitAt(0), alphaToInt);
      int ch3 = _btoi(s[inCursor++].codeUnitAt(0), alphaToInt);
      result[outCursor++] = (((ch0 << 2) | (ch1 >> 4)) & 0xff).toInt();
      result[outCursor++] = (((ch1 << 4) | (ch2 >> 2)) & 0xff).toInt();
      result[outCursor++] = (((ch2 << 6) | ch3) & 0xff).toInt();
    }

    if (missingBytesInLastGroup != 0) {
      int ch0 = _btoi(s[inCursor++].codeUnitAt(0), alphaToInt);
      int ch1 = _btoi(s[inCursor++].codeUnitAt(0), alphaToInt);
      result[outCursor++] = (((ch0 << 2) | (ch1 >> 4)) & 0xff).toInt();

      if (missingBytesInLastGroup == 1) {
        int ch2 = _btoi(s[inCursor++].codeUnitAt(0), alphaToInt);
        result[outCursor++] = (((ch1 << 4) | (ch2 >> 2)) & 0xff).toInt();
      }
    }
    return result;
  }

  static int _btoi(int c, List<int> alphaToInt) {
    int result = alphaToInt[c];
    if (result < 0) {
      throw ArgumentError("Illegal character $c");
    }
    return result;
  }

  static const List<int> _btoi_list = [
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    62,
    -1,
    -1,
    -1,
    63,
    52,
    53,
    54,
    55,
    56,
    57,
    58,
    59,
    60,
    61,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    0,
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15,
    16,
    17,
    18,
    19,
    20,
    21,
    22,
    23,
    24,
    25,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    26,
    27,
    28,
    29,
    30,
    31,
    32,
    33,
    34,
    35,
    36,
    37,
    38,
    39,
    40,
    41,
    42,
    43,
    44,
    45,
    46,
    47,
    48,
    49,
    50,
    51,
  ];

  static const List<int> _abtoi_list = [
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    0,
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    -1,
    62,
    9,
    10,
    11,
    -1,
    52,
    53,
    54,
    55,
    56,
    57,
    58,
    59,
    60,
    61,
    12,
    13,
    14,
    -1,
    15,
    63,
    16,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    17,
    -1,
    18,
    19,
    21,
    20,
    26,
    27,
    28,
    29,
    30,
    31,
    32,
    33,
    34,
    35,
    36,
    37,
    38,
    39,
    40,
    41,
    42,
    43,
    44,
    45,
    46,
    47,
    48,
    49,
    50,
    51,
    22,
    23,
    24,
    25,
  ];
}
