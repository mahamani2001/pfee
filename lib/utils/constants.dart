import 'dart:convert';

import 'package:intl/intl.dart';

final formatter = NumberFormat('#,##0.00', 'fr_FR');
const deviceIdShared = 'deviceId';
const String currency = '€';
RegExp regNum = RegExp('^(?=.*[0-9])');
//RegExp regspcl = RegExp(r'[!@#<>?:._;[\]|=+)(*&%-]');
RegExp regspcl = RegExp(r'[.!@#<>?:._;[\]|=+)(*&%-]');
RegExp regSpace = RegExp('^(?=.*[!*s])');
String patternUpper = '[A-Z]+';
RegExp regExpUpper = RegExp(patternUpper);
Codec<String?, String?> stringToBase64Url = utf8.fuse(base64Url);
const String urlResetPwd = 'https://www.google.com/';
const String urlReglemnt = 'https://www.google.com/';
const String urlCGU = 'https://www.google.com/';
const String urlPolitique = 'https://www.google.com/';
const String urlLeCercle = 'https://www.google.com/';
const String urlmypsy = 'https://www.google.com/';

const String PSY_ROLE = 'psychiatrist';
