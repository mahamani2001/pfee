import 'dart:developer';
import 'package:mypsy_app/resources/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart';

class SignallingService {
  Socket? socket;

  SignallingService._();
  static final instance = SignallingService._();

  Future<void> init({
    required String websocketUrl,
  }) async {
    // Get or refresh token BEFORE creating socket
    String? token = await AuthService().getJwtToken();
    if (token == null || AuthService.isTokenExpired(token)) {
      print('🔁 Token expiré. Tentative de refresh...');
      final refreshedToken = await AuthService().refreshToken();
      if (refreshedToken != null) {
        token = refreshedToken;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt', refreshedToken);
        print('✅ Token rafraîchi avec succès pour le socket');
      } else {
        print('❌ Impossible de rafraîchir le token. Déconnexion forcée.');
        return;
      }
    }
    final userId = await AuthService().getUserId();
    // Now connect the socket with token in auth
    socket = io(websocketUrl, {
      "transports": ['websocket'],
      "query": {"callerId": userId},
      "auth": {"token": token},
    });

    socket!.onConnect((data) {
      log("✅ Socket connected with token.");
    });

    socket!.onConnectError((data) {
      log("❌ Connect Error: $data");
    });

    socket!.connect();
  }
}
