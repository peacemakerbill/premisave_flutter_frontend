/// A currency a person can choose as their default: its code and its name.
class CurrencyInfo {
  const CurrencyInfo(this.code, this.name);

  final String code;
  final String name;
}

/// The currencies offered in the currency setting. The wallet keeps its balance in US dollars whichever one is chosen.
const List<CurrencyInfo> currencyChoices = <CurrencyInfo>[
  CurrencyInfo('USD', 'US dollar'),
  CurrencyInfo('KES', 'Kenyan shilling'),
  CurrencyInfo('EUR', 'Euro'),
  CurrencyInfo('GBP', 'British pound'),
  CurrencyInfo('UGX', 'Ugandan shilling'),
  CurrencyInfo('TZS', 'Tanzanian shilling'),
  CurrencyInfo('RWF', 'Rwandan franc'),
  CurrencyInfo('ETB', 'Ethiopian birr'),
  CurrencyInfo('NGN', 'Nigerian naira'),
  CurrencyInfo('GHS', 'Ghanaian cedi'),
  CurrencyInfo('ZAR', 'South African rand'),
  CurrencyInfo('EGP', 'Egyptian pound'),
  CurrencyInfo('MAD', 'Moroccan dirham'),
  CurrencyInfo('AED', 'UAE dirham'),
  CurrencyInfo('SAR', 'Saudi riyal'),
  CurrencyInfo('INR', 'Indian rupee'),
  CurrencyInfo('CNY', 'Chinese yuan'),
  CurrencyInfo('JPY', 'Japanese yen'),
  CurrencyInfo('KRW', 'South Korean won'),
  CurrencyInfo('SGD', 'Singapore dollar'),
  CurrencyInfo('AUD', 'Australian dollar'),
  CurrencyInfo('NZD', 'New Zealand dollar'),
  CurrencyInfo('CAD', 'Canadian dollar'),
  CurrencyInfo('CHF', 'Swiss franc'),
  CurrencyInfo('SEK', 'Swedish krona'),
  CurrencyInfo('NOK', 'Norwegian krone'),
  CurrencyInfo('DKK', 'Danish krone'),
  CurrencyInfo('PLN', 'Polish zloty'),
  CurrencyInfo('TRY', 'Turkish lira'),
  CurrencyInfo('BRL', 'Brazilian real'),
  CurrencyInfo('MXN', 'Mexican peso'),
];

/// The same currencies as a map of code to "CODE, name", for a select box.
final Map<String, String> currencyOptions = <String, String>{
  for (final c in currencyChoices) c.code: '${c.code}, ${c.name}',
};
