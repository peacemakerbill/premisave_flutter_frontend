import '../../core/network/api_client.dart';
import '../models/json_utils.dart';

/// What the server answers once a Contact us message is accepted.
class ContactReceipt {
  const ContactReceipt({required this.reference, required this.message});

  /// Short code to quote when writing to the team about this message.
  final String reference;
  final String message;
}

/// POST /contact. Open to signed out visitors too.
class ContactRepository {
  ContactRepository(this._api);

  final ApiClient _api;

  Future<ContactReceipt> send({
    required String name,
    required String email,
    required String topic,
    required String message,
  }) async {
    final res = await _api.post('/contact', body: <String, dynamic>{
      'name': name.trim(),
      'email': email.trim(),
      'topic': topic,
      'message': message.trim(),
    });
    final map = asMap(res);
    return ContactReceipt(
      reference: strOr(map['reference']),
      message: strOr(map['message'], 'Thank you, your message is with the Premisave team. We will reply by email.'),
    );
  }
}
