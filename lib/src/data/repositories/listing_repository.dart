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

  /// 2026-12-01T14:00:00, the form the listing service reads for a date and time.
  String _stamp(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}T${two(d.hour)}:${two(d.minute)}:00';
  }
}
