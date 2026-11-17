import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/storage_models.dart';
import 'providers.dart';

/// Where the messenger keeps its files, for administrators. Only watch it for an administrator: everyone else gets a 403.
final storageSettingsProvider =
    FutureProvider.autoDispose<StorageSettings>((ref) => ref.watch(storageRepositoryProvider).settings());

/// Where the auth service keeps uploaded documents, for administrators.
final documentStorageProvider = FutureProvider.autoDispose<DocumentStorageSettings>(
    (ref) => ref.watch(documentStorageRepositoryProvider).settings());
