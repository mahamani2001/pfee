import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class GoogleCalendarHelper {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        '898470772403-usb471r2oj7f06curfaa1g61dt7o75ls.apps.googleusercontent.com',
    scopes: ['https://www.googleapis.com/auth/calendar'],
  );

  GoogleSignInAccount? _currentUser;

  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  Future<bool> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      if (_currentUser == null) {
        print("⚠️ Connexion annulée");
        return false;
      }
      print("✅ Utilisateur connecté : ${_currentUser!.email}");
      return true;
    } catch (e) {
      print('❌ Erreur connexion Google: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    print("🔓 Déconnecté");
  }

  Future<bool> addEventToGoogleCalendar({
    required String title,
    required String description,
    required String location,
    required DateTime start,
    required DateTime end,
  }) async {
    if (_currentUser == null) {
      print("❌ Utilisateur non connecté");
      return false;
    }

    try {
      final auth = await _currentUser!.authentication;
      final token = auth.accessToken;

      final event = {
        'summary': title,
        'description': description,
        'location': location,
        'start': {
          'dateTime': start.toIso8601String(),
          'timeZone': 'Europe/Paris',
        },
        'end': {
          'dateTime': end.toIso8601String(),
          'timeZone': 'Europe/Paris',
        },
      };

      final response = await http.post(
        Uri.parse(
            "https://www.googleapis.com/calendar/v3/calendars/primary/events"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(event),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Événement ajouté avec succès !");
        return true;
      } else {
        print("❌ Échec ajout Google Calendar : ${response.statusCode}");
        print("📩 Détail : ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Exception ajout calendrier : $e");
      return false;
    }
  }
}
