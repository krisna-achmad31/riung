import 'package:riung/core/services/api/api_client.dart';

/// Backend/dev tooling only. The mobile app must never call RTDN or carry a
/// Pub/Sub bearer token. Production calls are made by Google Pub/Sub with OIDC.
class GooglePlayWebhookClient {
  GooglePlayWebhookClient(this.client);
  final ApiClient client;
  Future<void> send({
    required String base64Data,
    required String messageId,
    required String subscription,
  }) async {
    await client.request(
      'POST',
      '/v1/webhooks/google-play',
      appCheck: false,
      body: {
        'message': {'data': base64Data, 'messageId': messageId},
        'subscription': subscription,
      },
    );
  }
}
