import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mypsy_app/helpers/user_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

String listSpecialCarc = "Un chiffre, Un symbole (!@#<>?:._;[]|=+)(*&%-)";

const listSymbole = "(!@#<>?:_;[]|=+)(*&%-)";
RegExp regNum = RegExp("^(?=.*[0-9])");
RegExp regspcl = RegExp(r'[.!@#<>?:._;[\]|=+)(*&%-]');
RegExp regSpace = RegExp("^(?=.*[!*s])");
String patternUpper = '[A-Z]+';
RegExp regExpUpper = RegExp(patternUpper);
//Save the user credentials
Future<dynamic> loginUser(String? usernameEncoded, String? pwdEncoded) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await UserSecureStorage.setUsername(usernameEncoded);
  await UserSecureStorage.setPwd(pwdEncoded);
  prefs.setBool('isLoggedIn', true);
  prefs.setBool('appOnPause', true);
}

//Check connection of device
Future<bool> checkAppConnection() async {
  ConnectivityResult connectivityResult =
      (await (Connectivity().checkConnectivity())) as ConnectivityResult;
  if (connectivityResult == ConnectivityResult.mobile) {
    return true;
  } else if (connectivityResult == ConnectivityResult.wifi) {
    return true;
  }
  return false;
}

String getUsername(String firstName, String lastName) {
  String userName = '';
  if (firstName.length > 1) {
    userName = firstName.substring(0, 1);
  }
  if (lastName.length > 1) {
    userName = '$userName.${lastName.substring(0, 1)}';
  }
  return userName;
}

String capitalizeFirstLetter(String input) {
  if (input.isEmpty) {
    return input;
  }
  return input[0].toUpperCase() +
      (input.length > 1 ? input.substring(1).toLowerCase() : '');
}

int? getUserId(SharedPreferences prefs) {
  if (!prefs.containsKey('userId')) return 0;
  return prefs.getInt('userId');
}

Map<String, String> formatDateTimeSeparately(String input) {
  DateTime parsedUtcTime = DateTime.parse(input);

// Extract the date and hour
  String date =
      "${parsedUtcTime.year}-${parsedUtcTime.month.toString().padLeft(2, '0')}-${parsedUtcTime.day.toString().padLeft(2, '0')}";
  String hour =
      "${parsedUtcTime.hour.toString().padLeft(2, '0')}:${parsedUtcTime.minute.toString().padLeft(2, '0')}";
  String formattedDate =
      DateFormat('d MMMM yyyy', 'fr_FR').format(DateTime.parse(date));

  return {
    'date': formattedDate,
    'time': hour,
  };
}

Future<void> launchLink(String url) async {
  if (await canLaunchUrl(Uri.parse(url))) {
    await launchUrl(Uri.parse(url));
  } else {
    throw 'Could not launch $url';
  }
}

String getFrenchFormat(String expirationDate) =>
    DateFormat('dd/MM/yyyy', 'fr_FR').format(DateTime.parse(expirationDate));

void printConsole(String msg) {
  if (kDebugMode) {
    print(msg);
  }
}

String formatDateFr(String date) {
  try {
    DateTime parsed =
        DateTime.parse(date).toLocal(); // 🔥 Ceci corrige le décalage UTC
    String formatted = DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(parsed);
    return capitalizeFirstLetter(formatted);
  } catch (e) {
    return date;
  }
}

getDateFromApi(String originalDateStr) {
  final inputFormat = DateFormat("yyyy-MM-dd");
  DateTime dateTime = inputFormat.parse(originalDateStr);
  final outputFormat = DateFormat("dd/MM/yyyy");
  String formattedDateStr = outputFormat.format(dateTime);
  return formattedDateStr;
}

String formatDateTimeFr(String date, String time) {
  try {
    final full = DateTime.parse('$date $time').toLocal();
    return DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR').format(full);
  } catch (e) {
    return '$date $time';
  }
}

DateTime getCurrentDate() => DateTime.now();

DateTime getFirstDateForAgeRange(int startAge) {
  int currentYear = getCurrentDate().year;
  int birthYear = currentYear - startAge;
  return DateTime(birthYear, 1, 1);
}

DateTime initialDate = getFirstDateForAgeRange(80);
DateTime firstDate = getFirstDateForAgeRange(80);
DateTime lastDate = getFirstDateForAgeRange(13);

String formatedSlot(String slot) {
  List<String> parts = slot.split('-');
  String formattedSlot = "${parts[0]}\n-\n${parts[1]}";

  return formattedSlot;
}
