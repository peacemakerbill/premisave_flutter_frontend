import 'package:flutter/foundation.dart';

/// A country from the built in list. The list works offline, so suggestions appear instantly.
@immutable
class Country {
  const Country(this.code, this.name, {this.dial = '', this.aliases = const <String>[]});

  /// ISO 3166-1 alpha-2 code, for example KE.
  final String code;

  /// Common English name, for example Kenya.
  final String name;

  /// International calling code without the plus, for example 254.
  final String dial;

  /// Other names people type, for example UK for the United Kingdom.
  final List<String> aliases;

  /// The calling code with its plus, for example +254.
  String get dialLabel => dial.isEmpty ? '' : '+$dial';

  /// Flag emoji built from the code. Some desktop systems show the two letters instead.
  String get flag => String.fromCharCodes(code.toUpperCase().codeUnits.map((c) => 0x1F1E6 + c - 0x41));

  static final List<Country> all = _parse();

  static final Map<String, Country> _byCode = <String, Country>{for (final c in all) c.code: c};

  static final Map<String, Country> _byName = _indexNames();

  static final Map<String, List<Country>> _byDial = _indexDial();

  static Country? byCode(String? code) => code == null ? null : _byCode[code.trim().toUpperCase()];

  /// The country whose name or alias equals [text] exactly, ignoring case and accents.
  static Country? byName(String? text) {
    if (text == null) return null;
    final key = fold(text);
    return key.isEmpty ? null : _byName[key];
  }

  /// The main country for a calling code. Several countries share some codes, such as 1 and 44.
  static Country? byDial(String dial) {
    final list = _byDial[dial];
    if (list == null || list.isEmpty) return null;
    final primary = _primaryForDial[dial];
    if (primary != null) {
      for (final c in list) {
        if (c.code == primary) return c;
      }
    }
    return list.first;
  }

  /// Splits an international number such as +254712345678 or 00254712345678 into its country and the rest.
  /// Returns null when the text does not start with a plus or 00, or the calling code is unknown.
  static PhoneParts? splitInternational(String input) {
    var t = input.trim().replaceAll(RegExp(r'[\s().\-]'), '');
    if (t.startsWith('00')) t = '+${t.substring(2)}';
    if (!t.startsWith('+')) return null;
    final digits = t.substring(1).replaceAll(RegExp(r'[^0-9]'), '');
    for (var len = 3; len >= 1; len--) {
      if (digits.length < len) continue;
      final c = byDial(digits.substring(0, len));
      if (c != null) return PhoneParts(c, digits.substring(len));
    }
    return null;
  }

  /// Countries matching what the user typed, best matches first.
  static List<Country> search(String query, {int limit = 6}) {
    final q = fold(query);
    if (q.isEmpty) return const <Country>[];
    final scored = <MapEntry<Country, int>>[];
    for (final c in all) {
      final rank = c._rank(q);
      if (rank != null) scored.add(MapEntry<Country, int>(c, rank));
    }
    scored.sort((a, b) {
      final byRank = a.value.compareTo(b.value);
      return byRank != 0 ? byRank : a.key.name.compareTo(b.key.name);
    });
    return <Country>[for (final e in scored.take(limit)) e.key];
  }

  int? _rank(String q) {
    final n = fold(name);
    if (n == q) return 0;
    if (q.length == 2 && code.toLowerCase() == q) return 0;
    if (n.startsWith(q)) return 1;
    for (final a in aliases) {
      final f = fold(a);
      if (f == q) return 1;
      if (f.startsWith(q)) return 2;
    }
    for (final word in n.split(' ')) {
      if (word.startsWith(q)) return 3;
    }
    if (q.length >= 3 && n.contains(q)) return 4;
    return null;
  }

  /// Lower case with the common accents removed, so "turkiye" finds Türkiye.
  static String fold(String input) {
    const from = 'àáâãäåçèéêëìíîïñòóôõöùúûüýÿ';
    const to = 'aaaaaaceeeeiiiinooooouuuuyy';
    final out = StringBuffer();
    for (final ch in input.trim().toLowerCase().split('')) {
      final i = from.indexOf(ch);
      out.write(i >= 0 ? to[i] : ch);
    }
    return out.toString();
  }

  static Map<String, List<Country>> _indexDial() {
    final map = <String, List<Country>>{};
    for (final c in all) {
      if (c.dial.isNotEmpty) map.putIfAbsent(c.dial, () => <Country>[]).add(c);
    }
    return map;
  }

  static Map<String, Country> _indexNames() {
    final map = <String, Country>{};
    for (final c in all) {
      map[fold(c.name)] = c;
      for (final a in c.aliases) {
        map[fold(a)] = c;
      }
    }
    return map;
  }

  static const Map<String, List<String>> _aliases = <String, List<String>>{
    'US': <String>['USA', 'United States of America', 'America'],
    'GB': <String>['UK', 'Great Britain', 'Britain', 'England', 'Scotland', 'Wales', 'Northern Ireland'],
    'AE': <String>['UAE', 'Emirates'],
    'CI': <String>['Ivory Coast'],
    'CD': <String>['DR Congo', 'DRC', 'Democratic Republic of the Congo', 'Congo Kinshasa'],
    'CG': <String>['Republic of the Congo', 'Congo Brazzaville'],
    'CZ': <String>['Czech Republic'],
    'MK': <String>['Macedonia'],
    'SZ': <String>['Swaziland'],
    'MM': <String>['Burma'],
    'KR': <String>['Korea', 'Republic of Korea'],
    'KP': <String>['DPRK'],
    'RU': <String>['Russian Federation'],
    'TR': <String>['Turkey'],
    'VN': <String>['Viet Nam'],
    'TL': <String>['East Timor'],
    'CV': <String>['Cabo Verde'],
    'NL': <String>['Holland'],
    'VA': <String>['Holy See'],
    'PS': <String>['State of Palestine'],
    'LA': <String>['Lao'],
    'IR': <String>['Persia'],
    'TZ': <String>['United Republic of Tanzania'],
    'BO': <String>['Bolivia'],
    'FM': <String>['Federated States of Micronesia'],
  };

  /// Which country a shared calling code points to when only the code is known.
  static const Map<String, String> _primaryForDial = <String, String>{
    '1': 'US', '7': 'RU', '39': 'IT', '44': 'GB', '47': 'NO', '61': 'AU', '64': 'NZ', '212': 'MA', '262': 'RE',
    '358': 'FI', '500': 'FK', '590': 'GP', '599': 'CW', '672': 'NF',
  };

  static const Map<String, String> _dialCodes = <String, String>{
    'AF': '93', 'AX': '358', 'AL': '355', 'DZ': '213', 'AS': '1', 'AD': '376', 'AO': '244', 'AI': '1', 'AQ': '672',
    'AG': '1', 'AR': '54', 'AM': '374', 'AW': '297', 'AU': '61', 'AT': '43', 'AZ': '994', 'BS': '1', 'BH': '973',
    'BD': '880', 'BB': '1', 'BY': '375', 'BE': '32', 'BZ': '501', 'BJ': '229', 'BM': '1', 'BT': '975', 'BO': '591',
    'BQ': '599', 'BA': '387', 'BW': '267', 'BV': '47', 'BR': '55', 'IO': '246', 'VG': '1', 'BN': '673', 'BG': '359',
    'BF': '226', 'BI': '257', 'CV': '238', 'KH': '855', 'CM': '237', 'CA': '1', 'KY': '1', 'CF': '236', 'TD': '235',
    'CL': '56', 'CN': '86', 'CX': '61', 'CC': '61', 'CO': '57', 'KM': '269', 'CG': '242', 'CD': '243', 'CK': '682',
    'CR': '506', 'CI': '225', 'HR': '385', 'CU': '53', 'CW': '599', 'CY': '357', 'CZ': '420', 'DK': '45', 'DJ': '253',
    'DM': '1', 'DO': '1', 'EC': '593', 'EG': '20', 'SV': '503', 'GQ': '240', 'ER': '291', 'EE': '372', 'SZ': '268',
    'ET': '251', 'FK': '500', 'FO': '298', 'FJ': '679', 'FI': '358', 'FR': '33', 'GF': '594', 'PF': '689', 'TF': '262',
    'GA': '241', 'GM': '220', 'GE': '995', 'DE': '49', 'GH': '233', 'GI': '350', 'GR': '30', 'GL': '299', 'GD': '1',
    'GP': '590', 'GU': '1', 'GT': '502', 'GG': '44', 'GN': '224', 'GW': '245', 'GY': '592', 'HT': '509', 'HM': '672',
    'VA': '39', 'HN': '504', 'HK': '852', 'HU': '36', 'IS': '354', 'IN': '91', 'ID': '62', 'IR': '98', 'IQ': '964',
    'IE': '353', 'IM': '44', 'IL': '972', 'IT': '39', 'JM': '1', 'JP': '81', 'JE': '44', 'JO': '962', 'KZ': '7',
    'KE': '254', 'KI': '686', 'XK': '383', 'KW': '965', 'KG': '996', 'LA': '856', 'LV': '371', 'LB': '961', 'LS': '266',
    'LR': '231', 'LY': '218', 'LI': '423', 'LT': '370', 'LU': '352', 'MO': '853', 'MG': '261', 'MW': '265', 'MY': '60',
    'MV': '960', 'ML': '223', 'MT': '356', 'MH': '692', 'MQ': '596', 'MR': '222', 'MU': '230', 'YT': '262', 'MX': '52',
    'FM': '691', 'MD': '373', 'MC': '377', 'MN': '976', 'ME': '382', 'MS': '1', 'MA': '212', 'MZ': '258', 'MM': '95',
    'NA': '264', 'NR': '674', 'NP': '977', 'NL': '31', 'NC': '687', 'NZ': '64', 'NI': '505', 'NE': '227', 'NG': '234',
    'NU': '683', 'NF': '672', 'KP': '850', 'MK': '389', 'MP': '1', 'NO': '47', 'OM': '968', 'PK': '92', 'PW': '680',
    'PS': '970', 'PA': '507', 'PG': '675', 'PY': '595', 'PE': '51', 'PH': '63', 'PN': '64', 'PL': '48', 'PT': '351',
    'PR': '1', 'QA': '974', 'RE': '262', 'RO': '40', 'RU': '7', 'RW': '250', 'BL': '590', 'SH': '290', 'KN': '1',
    'LC': '1', 'MF': '590', 'PM': '508', 'VC': '1', 'WS': '685', 'SM': '378', 'ST': '239', 'SA': '966', 'SN': '221',
    'RS': '381', 'SC': '248', 'SL': '232', 'SG': '65', 'SX': '1', 'SK': '421', 'SI': '386', 'SB': '677', 'SO': '252',
    'ZA': '27', 'GS': '500', 'KR': '82', 'SS': '211', 'ES': '34', 'LK': '94', 'SD': '249', 'SR': '597', 'SJ': '47',
    'SE': '46', 'CH': '41', 'SY': '963', 'TW': '886', 'TJ': '992', 'TZ': '255', 'TH': '66', 'TL': '670', 'TG': '228',
    'TK': '690', 'TO': '676', 'TT': '1', 'TN': '216', 'TR': '90', 'TM': '993', 'TC': '1', 'TV': '688', 'UG': '256',
    'UA': '380', 'AE': '971', 'GB': '44', 'US': '1', 'UM': '1', 'VI': '1', 'UY': '598', 'UZ': '998', 'VU': '678',
    'VE': '58', 'VN': '84', 'WF': '681', 'EH': '212', 'YE': '967', 'ZM': '260', 'ZW': '263',
  };

  static List<Country> _parse() {
    return <Country>[
      for (final row in _raw)
        Country(
          row.substring(0, 2),
          row.substring(3),
          dial: _dialCodes[row.substring(0, 2)] ?? '',
          aliases: _aliases[row.substring(0, 2)] ?? const <String>[],
        ),
    ];
  }

  // Code, then the common English name.
  static const List<String> _raw = <String>[
    'AF|Afghanistan', 'AX|Åland Islands', 'AL|Albania', 'DZ|Algeria', 'AS|American Samoa', 'AD|Andorra', 'AO|Angola',
    'AI|Anguilla', 'AQ|Antarctica', 'AG|Antigua and Barbuda', 'AR|Argentina', 'AM|Armenia', 'AW|Aruba', 'AU|Australia',
    'AT|Austria', 'AZ|Azerbaijan', 'BS|Bahamas', 'BH|Bahrain', 'BD|Bangladesh', 'BB|Barbados', 'BY|Belarus',
    'BE|Belgium', 'BZ|Belize', 'BJ|Benin', 'BM|Bermuda', 'BT|Bhutan', 'BO|Bolivia', 'BQ|Caribbean Netherlands',
    'BA|Bosnia and Herzegovina', 'BW|Botswana', 'BV|Bouvet Island', 'BR|Brazil', 'IO|British Indian Ocean Territory',
    'VG|British Virgin Islands', 'BN|Brunei', 'BG|Bulgaria', 'BF|Burkina Faso', 'BI|Burundi', 'CV|Cape Verde',
    'KH|Cambodia', 'CM|Cameroon', 'CA|Canada', 'KY|Cayman Islands', 'CF|Central African Republic', 'TD|Chad',
    'CL|Chile', 'CN|China', 'CX|Christmas Island', 'CC|Cocos (Keeling) Islands', 'CO|Colombia', 'KM|Comoros',
    'CG|Congo (Republic)', 'CD|Congo (DR Congo)', 'CK|Cook Islands', 'CR|Costa Rica', "CI|Côte d'Ivoire", 'HR|Croatia',
    'CU|Cuba', 'CW|Curaçao', 'CY|Cyprus', 'CZ|Czechia', 'DK|Denmark', 'DJ|Djibouti', 'DM|Dominica',
    'DO|Dominican Republic', 'EC|Ecuador', 'EG|Egypt', 'SV|El Salvador', 'GQ|Equatorial Guinea', 'ER|Eritrea',
    'EE|Estonia', 'SZ|Eswatini', 'ET|Ethiopia', 'FK|Falkland Islands', 'FO|Faroe Islands', 'FJ|Fiji', 'FI|Finland',
    'FR|France', 'GF|French Guiana', 'PF|French Polynesia', 'TF|French Southern Territories', 'GA|Gabon', 'GM|Gambia',
    'GE|Georgia', 'DE|Germany', 'GH|Ghana', 'GI|Gibraltar', 'GR|Greece', 'GL|Greenland', 'GD|Grenada', 'GP|Guadeloupe',
    'GU|Guam', 'GT|Guatemala', 'GG|Guernsey', 'GN|Guinea', 'GW|Guinea-Bissau', 'GY|Guyana', 'HT|Haiti',
    'HM|Heard Island and McDonald Islands', 'VA|Vatican City', 'HN|Honduras', 'HK|Hong Kong', 'HU|Hungary',
    'IS|Iceland', 'IN|India', 'ID|Indonesia', 'IR|Iran', 'IQ|Iraq', 'IE|Ireland', 'IM|Isle of Man', 'IL|Israel',
    'IT|Italy', 'JM|Jamaica', 'JP|Japan', 'JE|Jersey', 'JO|Jordan', 'KZ|Kazakhstan', 'KE|Kenya', 'KI|Kiribati',
    'XK|Kosovo', 'KW|Kuwait', 'KG|Kyrgyzstan', 'LA|Laos', 'LV|Latvia', 'LB|Lebanon', 'LS|Lesotho', 'LR|Liberia',
    'LY|Libya', 'LI|Liechtenstein', 'LT|Lithuania', 'LU|Luxembourg', 'MO|Macao', 'MG|Madagascar', 'MW|Malawi',
    'MY|Malaysia', 'MV|Maldives', 'ML|Mali', 'MT|Malta', 'MH|Marshall Islands', 'MQ|Martinique', 'MR|Mauritania',
    'MU|Mauritius', 'YT|Mayotte', 'MX|Mexico', 'FM|Micronesia', 'MD|Moldova', 'MC|Monaco', 'MN|Mongolia',
    'ME|Montenegro', 'MS|Montserrat', 'MA|Morocco', 'MZ|Mozambique', 'MM|Myanmar', 'NA|Namibia', 'NR|Nauru',
    'NP|Nepal', 'NL|Netherlands', 'NC|New Caledonia', 'NZ|New Zealand', 'NI|Nicaragua', 'NE|Niger', 'NG|Nigeria',
    'NU|Niue', 'NF|Norfolk Island', 'KP|North Korea', 'MK|North Macedonia', 'MP|Northern Mariana Islands',
    'NO|Norway', 'OM|Oman', 'PK|Pakistan', 'PW|Palau', 'PS|Palestine', 'PA|Panama', 'PG|Papua New Guinea',
    'PY|Paraguay', 'PE|Peru', 'PH|Philippines', 'PN|Pitcairn Islands', 'PL|Poland', 'PT|Portugal', 'PR|Puerto Rico',
    'QA|Qatar', 'RE|Réunion', 'RO|Romania', 'RU|Russia', 'RW|Rwanda', 'BL|Saint Barthélemy', 'SH|Saint Helena',
    'KN|Saint Kitts and Nevis', 'LC|Saint Lucia', 'MF|Saint Martin', 'PM|Saint Pierre and Miquelon',
    'VC|Saint Vincent and the Grenadines', 'WS|Samoa', 'SM|San Marino', 'ST|São Tomé and Príncipe',
    'SA|Saudi Arabia', 'SN|Senegal', 'RS|Serbia', 'SC|Seychelles', 'SL|Sierra Leone', 'SG|Singapore',
    'SX|Sint Maarten', 'SK|Slovakia', 'SI|Slovenia', 'SB|Solomon Islands', 'SO|Somalia', 'ZA|South Africa',
    'GS|South Georgia and the South Sandwich Islands', 'KR|South Korea', 'SS|South Sudan', 'ES|Spain', 'LK|Sri Lanka',
    'SD|Sudan', 'SR|Suriname', 'SJ|Svalbard and Jan Mayen', 'SE|Sweden', 'CH|Switzerland', 'SY|Syria', 'TW|Taiwan',
    'TJ|Tajikistan', 'TZ|Tanzania', 'TH|Thailand', 'TL|Timor-Leste', 'TG|Togo', 'TK|Tokelau', 'TO|Tonga',
    'TT|Trinidad and Tobago', 'TN|Tunisia', 'TR|Türkiye', 'TM|Turkmenistan', 'TC|Turks and Caicos Islands',
    'TV|Tuvalu', 'UG|Uganda', 'UA|Ukraine', 'AE|United Arab Emirates', 'GB|United Kingdom', 'US|United States',
    'UM|U.S. Outlying Islands', 'VI|U.S. Virgin Islands', 'UY|Uruguay', 'UZ|Uzbekistan', 'VU|Vanuatu',
    'VE|Venezuela', 'VN|Vietnam', 'WF|Wallis and Futuna', 'EH|Western Sahara', 'YE|Yemen', 'ZM|Zambia',
    'ZW|Zimbabwe',
  ];
}

/// A phone number split into its country and the number inside that country.
@immutable
class PhoneParts {
  const PhoneParts(this.country, this.national);

  final Country country;

  /// Digits after the calling code.
  final String national;
}
