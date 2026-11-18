import 'dart:math';

final Random _random = Random.secure();

/// A random key for an `Idempotency-Key` header: 32 hex characters. Make one when a form opens and reuse it
/// for every retry of that one action, so the server can tell a retry from a second booking.
String newIdempotencyKey() {
  final buffer = StringBuffer();
  for (var i = 0; i < 16; i++) {
    buffer.write(_random.nextInt(256).toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}
