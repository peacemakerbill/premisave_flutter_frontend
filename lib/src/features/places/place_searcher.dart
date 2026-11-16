import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/place.dart';
import '../../data/repositories/place_repository.dart';

/// Search as you type for addresses. Waits for a pause in typing, ignores answers that arrive late
/// and tells the screen when the search is busy or could not be reached.
class PlaceSearcher extends ChangeNotifier {
  PlaceSearcher(this._repository, {this.countryCode});

  final PlaceRepository _repository;

  /// Results in this country (ISO code) are listed first.
  String? countryCode;

  List<Place> results = const <Place>[];
  bool loading = false;
  bool failed = false;

  /// True once a search has finished for the current text, so the screen can say "no matches".
  bool searched = false;

  Timer? _wait;
  CancelToken? _cancel;
  int _turn = 0;
  bool _disposed = false;

  void search(String text) {
    _wait?.cancel();
    _cancel?.cancel();
    final q = text.trim();
    final turn = ++_turn;
    if (q.length < 3) {
      results = const <Place>[];
      loading = false;
      failed = false;
      searched = false;
      _notify();
      return;
    }
    loading = true;
    failed = false;
    searched = false;
    _notify();
    _wait = Timer(const Duration(milliseconds: 380), () async {
      final token = CancelToken();
      _cancel = token;
      try {
        final found = await _repository.search(q, countryCode: countryCode, cancelToken: token);
        if (turn != _turn) return;
        results = found;
        failed = false;
      } catch (e) {
        if (turn != _turn || (e is DioException && CancelToken.isCancel(e))) return;
        results = const <Place>[];
        failed = true;
      }
      loading = false;
      searched = true;
      _notify();
    });
  }

  void clear() {
    _wait?.cancel();
    _cancel?.cancel();
    _turn++;
    results = const <Place>[];
    loading = false;
    failed = false;
    searched = false;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _wait?.cancel();
    _cancel?.cancel();
    super.dispose();
  }
}
