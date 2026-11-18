import 'json_utils.dart';

/// The answer of the C2B Hakikisha name lookup.
class NameLookupResult {
  NameLookupResult.fromJson(Map<String, dynamic> j)
      : accountName = strOr(j['accountName']),
        accountNumber = strOr(j['accountNumber']),
        shortcode = str(j['shortcode']),
        requestId = str(j['requestId']);

  final String accountName;
  final String accountNumber;
  final String? shortcode;
  final String? requestId;
}

/// A wallet account the C2B service keeps a copy of, for answering lookups.
class SavedAccount {
  SavedAccount.fromJson(Map<String, dynamic> j)
      : accountNumber = strOr(j['accountNumber']),
        fullName = strOr(j['fullName']),
        frozen = boolOr(j['frozen']),
        mpesaPhoneNumber = str(j['mpesaPhoneNumber']),
        pochiPhoneNumber = str(j['pochiPhoneNumber']),
        lastSyncedAt = dateOrNull(j['lastSyncedAt']);

  final String accountNumber;
  final String fullName;
  final bool frozen;
  final String? mpesaPhoneNumber;
  final String? pochiPhoneNumber;
  final DateTime? lastSyncedAt;
}
