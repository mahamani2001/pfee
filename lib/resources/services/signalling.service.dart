import 'dart:developer';
import 'package:mypsy_app/resources/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart';

class SignallingService {
  // instance of Socket
  Socket? socket;

  SignallingService._();
  static final instance = SignallingService._();

  init({required String websocketUrl, required String selfCallerID}) {
    // init Socket
    socket = io(websocketUrl, {
      "transports": ['websocket'],
      "query": {"callerId": selfCallerID}
    });

    // listen onConnect event
    socket!.onConnect((data) async {
      if (socket != null && socket!.connected) {
        print('🟢 Socket déjà connecté.');
        return;
      }

      var token = await AuthService().getJwtToken();
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
      log("Socket connected !!");
    });

    // listen onConnectError event
    socket!.onConnectError((data) {
      log("Connect Error $data");
    });

    // connect socket
    socket!.connect();
  }
}
