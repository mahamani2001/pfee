import 'dart:convert';

import 'package:mypsy_app/helpers/app_config.dart';
import 'package:mypsy_app/resources/error_response.dart';
import 'package:mypsy_app/utils/functions.dart';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum PathNames { getAppVersion, home, login, me }

const Map<PathNames, String> paths = {
  PathNames.getAppVersion: 'app-versions',
  PathNames.login: 'auth/login',
  PathNames.me: 'auth/me',
};

class mypsyApi {
  Dio dio = Dio();
  String? baseUrl, esBaseUrl, spendllyPro;
  mypsyApi() {
    baseUrl = AppConfig.instance()!.baseUrl;
  }

  Future<String?> getHiveToken() async {
    Box box = await Hive.openBox('authBox2');
    dynamic token = box.get('token');
    String? output;
    if (token != null) {
      output = token.containsKey('token') ? token['token'] : null;
      DateTime tokenAge = token['createdAt'];
      if (DateTime.now().difference(tokenAge).inDays > 30) {
        Dio refreshDio = Dio();
        String? username = box.get('username');
        String? password = box.get('password');

        try {
          dynamic res = await refreshDio.post(
            '$baseUrl/${paths[PathNames.login]}',
            data: {'email': username, 'password': password, 'source': 'app'},
          );
          printConsole('refreshed token -> done $username $password');
          box.put('token', {'token': res['jwt'], 'createdAt': DateTime.now()});
          output = res.data;
        } catch (e) {
          if (e is DioException) {
            printConsole('Dio error on refrsh token-> ${e.message} - $token');
          }
        }
      }
    }

    return output;
  }

  Map<String, dynamic> _getOptions(String? token) {
    Map<String, dynamic> output = {};

    output['Accept'] = 'application/json';
    output['Content-Type'] = 'application/json';
    output['User-Agent'] = 'flutter';

    if (token != null) {
      output['Authorization'] = 'Bearer $token';
    }

    return output;
  }

  Future<dynamic> getAppVersion() async {
    printConsole(' Get API :getAppVersion ');
    dynamic res = await get('${paths[PathNames.getAppVersion]}');
    return res;
  }

  /// **************************** CRUD part *****************************
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? params,
    bool needsAuth = false,
    bool withToken = false,
    String? withParams,
  }) async {
    String? token;

    if (needsAuth) {
      token = await getHiveToken();
    }

    String uri = '$baseUrl/$path';
    if (withParams != null) uri = '$uri&$withParams';
    Response? response;

    //  printConsole("_______ URI   $path ");

    try {
      try {
        response = await dio.get(
          uri,
          queryParameters: params,
          options: Options(
            headers: _getOptions(token),
          ),
        );
      } catch (e) {
        // printConsole('$_uri Get error -> $e');
        if (e is DioException) {
          if (e.response!.statusCode == 400 ||
              e.response!.statusCode == 404 ||
              e.response!.statusCode == 403 ||
              e.response!.statusCode == 401 ||
              e.response!.statusCode == 503 ||
              e.response!.statusCode == 500) {
            if (jsonDecode(e.response.toString())['result'] != null) {
              return ErrorResponse(
                errorCode: e.response!.statusCode,
                errorDescription: jsonDecode(e.response.toString())['result'],
              );
            }
            if (jsonDecode(e.response.toString())['message'] != null) {
              return ErrorResponse(
                errorCode: e.response!.statusCode,
                errorDescription: jsonDecode(e.response.toString())['message'],
              );
            }

            if (e.response!.statusMessage != null) {
              return ErrorResponse(
                errorCode: e.response!.statusCode,
                errorDescription: e.response!.statusMessage,
              );
            }
          }
        }
      }

      switch (response!.statusCode) {
        case 200:
          return response;
        case 201:
          return true;
        default:
          return ErrorResponse(
            errorCode: response.statusCode,
            errorDescription: response.data,
          );
      }
    } catch (e) {
      printConsole('[get] error -> $e');
    }
  }

  Future<dynamic> post(
    String path, {
    dynamic body,
    bool needsAuth = true,
    bool withToken = false,
    String? withParms,
  }) async {
    late Response response;
    String? token;
    if (needsAuth) {
      token = await getHiveToken();
    }
    String uri = '$baseUrl/$path';
    if (withParms != null) uri = '$uri&$withParms';

    String urlprintConsole = '$baseUrl/$path';
    if (withParms != null) urlprintConsole = '$urlprintConsole&$withParms';

    printConsole('_______ URI POST $urlprintConsole ');
    // developer.log("_______ PARAMETRS $body ");

    try {
      try {
        response = await dio.post(
          uri,
          data: body,
          options: Options(
            headers: _getOptions(token),
          ),
        );
      } catch (e) {
        if (e is DioException) {
          if (e.response != null &&
              (e.response!.statusCode == 406 ||
                  e.response!.statusCode == 400 ||
                  e.response!.statusCode == 422 ||
                  e.response!.statusCode == 423 ||
                  e.response!.statusCode == 429 ||
                  e.response!.statusCode == 428 ||
                  e.response!.statusCode == 427 ||
                  e.response!.statusCode == 424 ||
                  e.response!.statusCode == 404 ||
                  e.response!.statusCode == 401 ||
                  e.response!.statusCode == 500 ||
                  e.response!.statusCode == 502 ||
                  e.response!.statusCode == 503)) {
            if (jsonDecode(e.response.toString())['error'] != null) {
              printConsole('--- Retour ${jsonDecode(e.response.toString())}');
              return ErrorResponse(
                error: e.response,
                errorCode: e.response!.statusCode,
                errorDescription: e.response.toString().contains('message')
                    ? jsonDecode(e.response.toString())['error']['message']
                        .toString()
                    : jsonDecode(e.response.toString())['error']['name']
                        .toString(),
              );
            }

            if (e.response!.statusMessage != null) {
              return ErrorResponse(
                errorCode: e.response!.statusCode,
                errorDescription: e.response!.statusMessage,
              );
            }
          } else {
            printConsole(
              '-- Error reponse without staus code ${e.response.toString()}',
            );
            return ErrorResponse(
              errorCode:
                  e.response != null ? e.response!.statusCode : e.hashCode,
              errorDescription: e.message,
            );
          }
        }
      }
      switch (response.statusCode) {
        case 200:
          return response.data;

        case 202:
          return response.data;

        case 201:
          return true;
        default:
          return ErrorResponse(
            errorCode: response.statusCode,
            errorDescription: response.data,
          );
      }
    } catch (e) {
      printConsole('  [post] error ($urlprintConsole)-> $e ');
      if (e is DioException) {
        return e.response!.statusCode;
      }
    }
  }

  Future<dynamic> put(
    String path, {
    dynamic body,
    bool needsAuth = true,
    bool withToken = false,
    String? withParms,
  }) async {
    late Response response;
    String? token;
    if (needsAuth) {
      token = await getHiveToken();
    }
    String uri = '$baseUrl/$path';
    if (withParms != null) uri = '$uri&$withParms';

    String urlprintConsole = '$baseUrl/$path';
    if (withParms != null) urlprintConsole = '$urlprintConsole&$withParms';

    printConsole('_______ URI POST $urlprintConsole ');
    // developer.log("_______ PARAMETRS $body ");

    try {
      try {
        response = await dio.put(
          uri,
          data: body,
          options: Options(
            headers: _getOptions(token),
          ),
        );
      } catch (e) {
        if (e is DioException) {
          if (e.response != null &&
              (e.response!.statusCode == 406 ||
                  e.response!.statusCode == 400 ||
                  e.response!.statusCode == 422 ||
                  e.response!.statusCode == 423 ||
                  e.response!.statusCode == 429 ||
                  e.response!.statusCode == 428 ||
                  e.response!.statusCode == 427 ||
                  e.response!.statusCode == 424 ||
                  e.response!.statusCode == 404 ||
                  e.response!.statusCode == 401 ||
                  e.response!.statusCode == 500 ||
                  e.response!.statusCode == 502 ||
                  e.response!.statusCode == 503)) {
            if (jsonDecode(e.response.toString())['error'] != null) {
              printConsole('--- Retour ${jsonDecode(e.response.toString())}');
              return ErrorResponse(
                error: e.response,
                errorCode: e.response!.statusCode,
                errorDescription: e.response.toString().contains('message')
                    ? jsonDecode(e.response.toString())['error']['message']
                        .toString()
                    : jsonDecode(e.response.toString())['error']['name']
                        .toString(),
              );
            }

            if (e.response!.statusMessage != null) {
              return ErrorResponse(
                errorCode: e.response!.statusCode,
                errorDescription: e.response!.statusMessage,
              );
            }
          } else {
            printConsole(
              '-- Error reponse without staus code ${e.response.toString()}',
            );
            return ErrorResponse(
              errorCode:
                  e.response != null ? e.response!.statusCode : e.hashCode,
              errorDescription: e.message,
            );
          }
        }
      }
      switch (response.statusCode) {
        case 200:
          return response.data;

        case 202:
          return response.data;

        case 201:
          return true;
        default:
          return ErrorResponse(
            errorCode: response.statusCode,
            errorDescription: response.data,
          );
      }
    } catch (e) {
      printConsole('  [post] error ($urlprintConsole)-> $e ');
      if (e is DioException) {
        return e.response!.statusCode;
      }
    }
  }

  //Delete address function
  Future<dynamic> delete(
    String path, {
    dynamic body,
    bool needsAuth = true,
    bool withToken = false,
    String? withParms,
  }) async {
    late Response response;
    String? token;
    if (needsAuth) {
      token = await getHiveToken();
    }
    String uri = '$baseUrl/$path';
    if (withParms != null) uri = '$uri&$withParms';

    String urlprintConsole = '$baseUrl/$path';
    if (withParms != null) urlprintConsole = '$urlprintConsole&$withParms';

    printConsole('_______ URI POST $urlprintConsole ');
    // developer.log("_______ PARAMETRS $body ");

    try {
      try {
        response = await dio.delete(
          uri,
          data: body,
          options: Options(
            headers: _getOptions(token),
          ),
        );
      } catch (e) {
        if (e is DioException) {
          printConsole('----->>> ${e.response}');
          if (e.response!.statusCode == 400 || e.response!.statusCode == 404) {
            return ErrorResponse(
              errorCode: e.response!.statusCode,
              errorDescription: e.response!.statusMessage,
            );
          }
        }
      }
      switch (response.statusCode) {
        case 200:
          return response.data;

        case 201:
          return true;
        case 204:
          return true;
        default:
          return ErrorResponse(
            errorCode: response.statusCode,
            errorDescription: response.data,
          );
      }
    } catch (e) {
      printConsole('[post] error ($uri)-> $e');
      if (e is DioException) {
        return e.response!.statusMessage;
      }
    }
  }
}
