import 'json_utils.dart';

/// A property listing as the listing service returns it. The same shape covers short stays, long term rentals,
/// leases and sales, and the owner's own list (GET /listings/me).
class ListingModel {
  ListingModel.fromJson(Map<String, dynamic> j)
      : id = strOr(j['id'] ?? j['listingId']),
        title = strOr(j['title'], 'Untitled listing'),
        description = str(j['description']),
        category = strOr(j['category']),
        status = str(j['status']),
        price = doubleOrNull(j['price']),
        priceUnit = str(j['priceUnit']),
        pricePerNight = doubleOrNull(j['pricePerNight']),
        pricePerDay = doubleOrNull(j['pricePerDay']),
        currency = strOr(j['currency'], 'USD'),
        city = str(j['city']),
        country = str(j['country']),
        address = str(j['address']),
        ownerId = str(j['ownerId']),
        mainImageUrl = str(j['mainImageUrl']),
        imageUrls = stringList(j['imageUrls']),
        promoted = boolOr(j['promoted'] ?? j['isPromoted']),
        maxGuests = intOrNull(j['maxGuests']),
        bedrooms = intOrNull(j['bedrooms']),
        bathrooms = intOrNull(j['bathrooms']),
        amenities = stringList(j['amenities']),
        cancellationPolicy = str(j['cancellationPolicy']),
        createdAt = dateOrNull(j['createdAt']);

  final String id;
  final String title;
  final String? description;

  /// SHORT_TERM_RENTAL, LONG_TERM_RENTAL, LAND_SALE, HOUSE_SALE or LEASE.
  final String category;

  /// PENDING, APPROVED and so on. Only the owner's list carries it.
  final String? status;
  final double? price;
  final String? priceUnit;
  final double? pricePerNight;
  final double? pricePerDay;
  final String currency;
  final String? city;
  final String? country;
  final String? address;
  final String? ownerId;
  final String? mainImageUrl;
  final List<String> imageUrls;
  final bool promoted;
  final int? maxGuests;
  final int? bedrooms;
  final int? bathrooms;
  final List<String> amenities;
  final String? cancellationPolicy;
  final DateTime? createdAt;

  bool get isShortStay => category == 'SHORT_TERM_RENTAL';

  /// The price a card shows: the nightly rate for a short stay, otherwise the listing price.
  double? get headlinePrice => isShortStay ? (pricePerNight ?? pricePerDay ?? price) : price;

  /// "night", "month" and so on, for the line under the price.
  String get priceLabel {
    if (isShortStay) return pricePerNight != null || priceUnit == 'PER_NIGHT' ? 'night' : 'day';
    switch (priceUnit) {
      case 'PER_MONTH':
        return 'month';
      case 'PER_DAY':
        return 'day';
      case 'PER_NIGHT':
        return 'night';
      default:
        return '';
    }
  }

  String get place => <String?>[city, country].where((e) => e != null && e.isNotEmpty).join(', ');

  String? get cover {
    if (mainImageUrl != null) return mainImageUrl;
    return imageUrls.isEmpty ? null : imageUrls.first;
  }
}

/// A booking of a short stay, either as the guest or as the host.
class BookingModel {
  BookingModel.fromJson(Map<String, dynamic> j)
      : id = strOr(j['id']),
        listingId = strOr(j['listingId']),
        checkIn = dateOrNull(j['checkIn']),
        checkOut = dateOrNull(j['checkOut']),
        priceUnit = str(j['priceUnit']),
        totalAmount = doubleOrNull(j['totalAmount']),
        currency = strOr(j['currency'], 'USD'),
        status = strOr(j['status'], 'PENDING'),
        message = str(j['message']),
        tenantName = _name(asMap(j['tenant'])),
        ownerName = _name(asMap(j['owner'])),
        cancellationPolicy = str(j['cancellationPolicy']),
        escrowStatus = str(j['escrowStatus']),
        refundAmount = doubleOrNull(j['refundAmount']),
        units = intOrNull(j['units']);

  static String? _name(Map<String, dynamic> m) {
    final full = str(m['fullName']) ?? str(m['name']);
    if (full != null) return full;
    final joined = <String?>[str(m['firstName']), str(m['lastName'])].whereType<String>().join(' ');
    return joined.isEmpty ? str(m['username']) : joined;
  }

  final String id;
  final String listingId;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String? priceUnit;
  final double? totalAmount;
  final String currency;

  /// PENDING, CONFIRMED, COMPLETED, CANCELLED, FAILED or NEEDS_REVIEW.
  final String status;
  final String? message;
  final String? tenantName;
  final String? ownerName;
  final String? cancellationPolicy;
  final String? escrowStatus;
  final double? refundAmount;
  final int? units;

  bool get cancellable => status == 'CONFIRMED' || status == 'PENDING';
}

/// What cancelling a booking would refund, from GET /bookings/{id}/cancellation-quote.
class CancellationQuote {
  CancellationQuote.fromJson(Map<String, dynamic> j)
      : policy = str(j['policy']),
        refundPercent = intOr(j['refundPercent']),
        refundAmount = doubleOrNull(j['refundAmount']) ?? 0,
        currency = strOr(j['currency'], 'USD'),
        message = str(j['message']);

  final String? policy;
  final int refundPercent;
  final double refundAmount;
  final String currency;
  final String? message;
}

/// Interest a person showed in a listing (the wishlist), or a lead the owner received.
class InterestModel {
  InterestModel.fromJson(Map<String, dynamic> j)
      : id = strOr(j['id']),
        listingId = strOr(j['listingId']),
        listingTitle = strOr(j['listingTitle'], 'Listing'),
        message = str(j['message']),
        createdAt = dateOrNull(j['createdAt']),
        customerName = BookingModel._name(asMap(j['customer']));

  final String id;
  final String listingId;
  final String listingTitle;
  final String? message;
  final DateTime? createdAt;
  final String? customerName;
}

/// Pages from the listing service look like Spring's Page: {content: [...], totalElements: n}.
List<Map<String, dynamic>> pageContent(Object? body) {
  final m = body is Map ? asMap(body) : <String, dynamic>{};
  if (m['content'] is List) return mapList(m['content']);
  return mapList(body);
}
