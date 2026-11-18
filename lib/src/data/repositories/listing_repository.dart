import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../models/json_utils.dart';
import '../models/listing_models.dart';
import 'messenger_repository.dart' show LocalFile;

/// The listing service: public search, the owner's listings, bookings and wishlist interests.
class ListingRepository {
  ListingRepository(this._api);

  final ApiClient _api;

  String _id(String s) => Uri.encodeComponent(s);

  /// Public listings. Every filter is optional.
  Future<List<ListingModel>> search({String? query, String? category, String? city, double? minPrice, double? maxPrice}) async {
    final res = await _api.get('/listings/search', query: compact(<String, dynamic>{
      'query': query,
      'category': category,
      'city': city,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
    }));
    return mapList(res).map(ListingModel.fromJson).toList();
  }

  Future<ListingModel> listing(String id) async => ListingModel.fromJson(asMap(await _api.get('/listings/${_id(id)}')));

  /// The signed in owner's own listings, with their review status.
  Future<List<ListingModel>> myListings({String? status}) async {
    final res = await _api.get('/listings/me', query: compact(<String, dynamic>{'status': status}));
    return mapList(res).map(ListingModel.fromJson).toList();
  }

  /// The same list as [myListings], as the service sent it, with every category specific field.
  Future<List<Map<String, dynamic>>> myListingsRaw({String? status, String? category, String? query}) async =>
      mapList(await _api.get('/listings/me', query: compact(<String, dynamic>{'status': status, 'category': category, 'query': query})));

  /// Creates a listing. The service reads it as a multipart request: a `request` part with the details as JSON and
  /// a `files` part per photo (up to 20, 10 MB each, 40 MB in all). The listing waits for review before the public can see it.
  Future<({String id, String message})> createListing(Map<String, dynamic> details, List<LocalFile> photos) async {
    final form = FormData();
    form.files.add(MapEntry<String, MultipartFile>(
      'request',
      MultipartFile.fromString(jsonEncode(details), filename: 'request.json', contentType: DioMediaType('application', 'json')),
    ));
    for (final photo in photos) {
      form.files.add(MapEntry<String, MultipartFile>('files', await photo.toMultipart()));
    }
    final res = asMap(await _api.upload('/listings', form));
    return (id: strOr(res['listingId']), message: strOr(res['message'], 'Listing submitted for review'));
  }

  Future<void> archive(String id) => _api.post('/listings/${_id(id)}/archive');

  Future<void> unarchive(String id) => _api.post('/listings/${_id(id)}/unarchive');

  /// Dates in [from, to] that are already taken, as yyyy-MM-dd strings.
  Future<List<String>> unavailableDates(String listingId, {required String from, required String to}) async {
    final res = await _api.get('/listings/${_id(listingId)}/availability', query: <String, dynamic>{'from': from, 'to': to});
    return stringList(asMap(res)['unavailableDates']);
  }

  /// The listing exactly as the service sends it, for the edit form that needs every category specific field.
  Future<Map<String, dynamic>> listingRaw(String id) async => asMap(await _api.get('/listings/${_id(id)}'));

  /// Edits a listing. Only the fields in [changes] are touched. New photos in [photos] are added to the listing.
  /// The service reads it as multipart, a `request` part with the changes as JSON and a `files` part per photo.
  Future<String> updateListing(String id, Map<String, dynamic> changes, {List<LocalFile> photos = const <LocalFile>[]}) async {
    final form = await _form(changes, photos);
    return _text(await _api.uploadWith('PUT', '/listings/${_id(id)}', form));
  }

  /// Deletes a listing for good. A listing with live bookings cannot be deleted, archive it instead.
  Future<String> deleteListing(String id) async => _text(await _api.delete('/listings/${_id(id)}'));

  /// Adds photos to a listing that already exists.
  Future<String> addImages(String id, List<LocalFile> photos) async {
    final form = FormData();
    for (final photo in photos) {
      form.files.add(MapEntry<String, MultipartFile>('files', await photo.toMultipart()));
    }
    return _text(await _api.uploadWith('POST', '/listings/${_id(id)}/images', form));
  }

  Future<String> removeImage(String id, String fileId) async => _text(await _api.delete('/listings/${_id(id)}/images/${_id(fileId)}'));

  Future<String> setCoverImage(String id, String fileId) async =>
      _text(await _api.put('/listings/${_id(id)}/images/cover', body: <String, dynamic>{'fileId': fileId}));

  Future<String> reorderImages(String id, List<String> fileIds) async =>
      _text(await _api.put('/listings/${_id(id)}/images/order', body: <String, dynamic>{'fileIds': fileIds}));

  /// Uploads photos without attaching them to a listing yet, and returns where they were stored.
  Future<({String? mainImageUrl, List<String> imageUrls})> uploadImages(List<LocalFile> photos) async {
    final form = FormData();
    for (final photo in photos) {
      form.files.add(MapEntry<String, MultipartFile>('files', await photo.toMultipart()));
    }
    final res = asMap(await _api.upload('/listings/upload-images', form));
    return (mainImageUrl: str(res['mainImageUrl']), imageUrls: stringList(res['imageUrls']));
  }

  /// A person's public listings.
  Future<List<ListingModel>> listingsByOwner(String ownerId, {String? category}) async {
    final res = await _api.get('/listings/owner/${_id(ownerId)}', query: compact(<String, dynamic>{'category': category}));
    return mapList(res).map(ListingModel.fromJson).toList();
  }

  Future<List<ListingModel>> shortTerm({String? city}) async {
    final res = await _api.get('/listings/short-term', query: compact(<String, dynamic>{'city': city}));
    return mapList(res).map(ListingModel.fromJson).toList();
  }

  // ------------------------------------------------------------ blocked dates

  /// Closes [from] to [to] (the last night stays open) so nobody can book it. Returns the block id.
  Future<String> blockDates(String listingId, {required DateTime from, required DateTime to}) async {
    final res = asMap(await _api.post('/listings/${_id(listingId)}/blocked-dates', body: <String, dynamic>{
      'from': _day(from),
      'to': _day(to),
    }));
    return strOr(res['blockId']);
  }

  Future<void> unblockDates(String listingId, String blockId) =>
      _api.delete('/listings/${_id(listingId)}/blocked-dates/${_id(blockId)}');

  // ---------------------------------------------------------------- promotion

  /// Pays to feature a listing at the top of Explore for [days] days.
  Future<Map<String, dynamic>> promote(String listingId, int days) async =>
      asMap(await _api.post('/listings/promote', body: <String, dynamic>{'listingId': listingId, 'days': days}));

  Future<Map<String, dynamic>> extendPromotion(String listingId, int days) async =>
      asMap(await _api.post('/listings/${_id(listingId)}/extend', query: <String, dynamic>{'days': days}));

  Future<List<Map<String, dynamic>>> myPromotions() async =>
      pageContent(await _api.get('/listings/promotions/my', query: <String, dynamic>{'size': 50}));

  // -------------------------------------------------------------- currency

  Future<({String base, Map<String, dynamic> rates})> currencyRates() async {
    final res = asMap(await _api.get('/currency/rates'));
    return (base: strOr(res['base'], 'USD'), rates: asMap(res['rates']));
  }

  Future<Map<String, dynamic>> currencyRate(String to) async => asMap(await _api.get('/currency/rate', query: <String, dynamic>{'to': to}));

  Future<Map<String, dynamic>> convertCurrency(double amount, String to) async =>
      asMap(await _api.get('/currency/convert', query: <String, dynamic>{'amount': amount, 'to': to}));

  Future<List<String>> supportedCurrencies() async {
    final res = await _api.get('/currency/supported');
    if (res is List) return res.map((e) => e.toString()).toList();
    final m = asMap(res);
    final inner = m['currencies'] ?? m['supported'] ?? m.keys.toList();
    return inner is List ? inner.map((e) => e.toString()).toList() : m.keys.toList();
  }

  // -------------------------------------------------------------- locations

  Future<List<ListingModel>> nearby(double latitude, double longitude, {double radiusKm = 10}) async {
    final res = await _api.get('/locations/nearby', query: <String, dynamic>{'latitude': latitude, 'longitude': longitude, 'radiusKm': radiusKm});
    return mapList(res).map(ListingModel.fromJson).toList();
  }

  Future<List<ListingModel>> inCity(String city) async =>
      mapList(await _api.get('/locations/city', query: <String, dynamic>{'city': city})).map(ListingModel.fromJson).toList();

  Future<List<ListingModel>> inBounds({required double minLat, required double maxLat, required double minLng, required double maxLng}) async {
    final res = await _api.get('/locations/bounds', query: <String, dynamic>{'minLat': minLat, 'maxLat': maxLat, 'minLng': minLng, 'maxLng': maxLng});
    return mapList(res).map(ListingModel.fromJson).toList();
  }

  // ----------------------------------------------------------- staff, listings

  /// Every listing for staff, with filters. [status] is PENDING, APPROVED, REJECTED and so on.
  Future<List<Map<String, dynamic>>> adminListings({String? status, bool? archived, bool? deleted, int page = 0}) async =>
      pageContent(await _api.get('/admin/listings', query: compact(<String, dynamic>{
        'status': status,
        'archived': archived,
        'deleted': deleted,
        'page': page,
        'size': 50,
      })));

  Future<Map<String, dynamic>> adminListing(String id) async => asMap(await _api.get('/admin/listings/${_id(id)}'));

  Future<String> approveListing(String id) async => _text(await _api.put('/admin/listings/${_id(id)}/approve'));

  Future<String> rejectListing(String id) async => _text(await _api.put('/admin/listings/${_id(id)}/reject'));

  Future<String> adminArchive(String id) async => _text(await _api.put('/admin/listings/${_id(id)}/archive'));

  Future<String> adminUnarchive(String id) async => _text(await _api.put('/admin/listings/${_id(id)}/unarchive'));

  Future<String> adminSoftDelete(String id) async => _text(await _api.delete('/admin/listings/${_id(id)}'));

  Future<String> adminRestore(String id) async => _text(await _api.put('/admin/listings/${_id(id)}/restore'));

  Future<String> adminHardDelete(String id) async => _text(await _api.delete('/admin/listings/${_id(id)}/hard-delete'));

  // ----------------------------------------------------------- staff, bookings

  /// The bookings needing review as the service sent them.
  Future<List<Map<String, dynamic>>> bookingsNeedingReviewRaw({int size = 50}) async =>
      pageContent(await _api.get('/admin/bookings/needs-review', query: <String, dynamic>{'size': size}));

  Future<BookingModel> retryPayout(String bookingId) async =>
      BookingModel.fromJson(asMap(await _api.post('/admin/bookings/${_id(bookingId)}/retry-payout')));

  /// Settles a booking whose payment could not be confirmed. [paid] true confirms it, false fails it and frees its dates.
  Future<BookingModel> resolvePayment(String bookingId, {required bool paid}) async =>
      BookingModel.fromJson(asMap(await _api.post('/admin/bookings/${_id(bookingId)}/resolve-payment', query: <String, dynamic>{'paid': paid})));

  // ------------------------------------------------------------------ bookings

  /// Books a stay. The money is held until check in. [idempotencyKey] makes a retry return the first booking.
  Future<BookingModel> book({
    required String listingId,
    required DateTime checkIn,
    required DateTime checkOut,
    required String priceUnit,
    String? idempotencyKey,
  }) async {
    final res = await _api.post(
      '/bookings',
      headers: idempotencyKey == null ? null : <String, dynamic>{'Idempotency-Key': idempotencyKey},
      body: <String, dynamic>{
        'listingId': listingId,
        'checkIn': _stamp(checkIn),
        'checkOut': _stamp(checkOut),
        'priceUnit': priceUnit,
      },
    );
    return BookingModel.fromJson(asMap(res));
  }

  Future<List<BookingModel>> myBookings({String? status}) async {
    final res = await _api.get('/bookings/me', query: compact(<String, dynamic>{'status': status, 'size': 50}));
    return pageContent(res).map(BookingModel.fromJson).toList();
  }

  Future<List<BookingModel>> receivedBookings({String? status}) async {
    final res = await _api.get('/bookings/received', query: compact(<String, dynamic>{'status': status, 'size': 50}));
    return pageContent(res).map(BookingModel.fromJson).toList();
  }

  /// Bookings whose payment or payout needs a person to look at it (Admin and Finance only).
  /// [total] counts all of them, [items] is the first page.
  Future<({int total, List<BookingModel> items})> bookingsNeedingReview({int size = 10}) async {
    final res = await _api.get('/admin/bookings/needs-review', query: <String, dynamic>{'size': size});
    final items = pageContent(res).map(BookingModel.fromJson).toList();
    final total = res is Map ? intOr(res['totalElements'], items.length) : items.length;
    return (total: total, items: items);
  }

  Future<CancellationQuote> cancellationQuote(String bookingId) async =>
      CancellationQuote.fromJson(asMap(await _api.get('/bookings/${_id(bookingId)}/cancellation-quote')));

  Future<BookingModel> cancelBooking(String bookingId, {String? reason}) async {
    final res = await _api.post('/bookings/${_id(bookingId)}/cancel', query: compact(<String, dynamic>{'reason': reason}));
    return BookingModel.fromJson(asMap(res));
  }

  // ----------------------------------------------------------------- interests

  /// Tells the owner of a rental, lease or sale listing that the person is interested. This is the wishlist.
  Future<InterestModel> expressInterest(String listingId, {String? message}) async {
    final res = await _api.post('/interests', body: compact(<String, dynamic>{'listingId': listingId, 'message': message}));
    return InterestModel.fromJson(asMap(res));
  }

  Future<void> cancelInterest(String id) => _api.delete('/interests/${_id(id)}');

  Future<List<InterestModel>> myInterests() async =>
      pageContent(await _api.get('/interests/me', query: <String, dynamic>{'size': 50})).map(InterestModel.fromJson).toList();

  Future<List<InterestModel>> receivedInterests() async =>
      pageContent(await _api.get('/interests/received', query: <String, dynamic>{'size': 50})).map(InterestModel.fromJson).toList();

  Future<FormData> _form(Map<String, dynamic> details, List<LocalFile> photos) async {
    final form = FormData();
    form.files.add(MapEntry<String, MultipartFile>(
      'request',
      MultipartFile.fromString(jsonEncode(details), filename: 'request.json', contentType: DioMediaType('application', 'json')),
    ));
    for (final photo in photos) {
      form.files.add(MapEntry<String, MultipartFile>('files', await photo.toMultipart()));
    }
    return form;
  }

  /// Several listing endpoints answer with a plain sentence, others with {message}. Both come back as text.
  String _text(dynamic res) {
    if (res is String) return res;
    if (res is Map) return strOr(res['message']);
    return '';
  }

  String _day(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  /// 2026-12-01T14:00:00, the form the listing service reads for a date and time.
  String _stamp(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}T${two(d.hour)}:${two(d.minute)}:00';
  }
}
