import 'package:mypsy_app/resources/api.dart';
import 'package:mypsy_app/resources/error_response.dart';
import 'package:mypsy_app/utils/functions.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppVersion {
  List<Data>? data;

  AppVersion({
    this.data,
  });

  AppVersion.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(Data.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Data {
  int? id;
  Attributes? attributes;

  Data({this.id, this.attributes});

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    attributes = json['attributes'] != null
        ? Attributes.fromJson(json['attributes'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    if (attributes != null) {
      data['attributes'] = attributes!.toJson();
    }
    return data;
  }
}

class Attributes {
  String? appVersion;
  String? minimumBuild;
  String? currentBuild;
  String? createdAt;
  String? updatedAt;
  String? publishedAt;

  Attributes({
    this.appVersion,
    this.minimumBuild,
    this.currentBuild,
    this.createdAt,
    this.updatedAt,
    this.publishedAt,
  });

  Attributes.fromJson(Map<String, dynamic> json) {
    appVersion = json['appVersion'];
    minimumBuild = json['minimumBuild'];
    currentBuild = json['currentBuild'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    publishedAt = json['publishedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['appVersion'] = appVersion;
    data['minimumBuild'] = minimumBuild;
    data['currentBuild'] = currentBuild;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['publishedAt'] = publishedAt;
    return data;
  }
}

PackageInfo _packageInfo = PackageInfo(
  appName: 'Unknown',
  packageName: 'Unknown',
  version: 'Unknown',
  buildNumber: 'Unknown',
);
PackageInfo? info;
AppVersion? version;

//check minimum app version required
Future<dynamic> checkForceUpdate(BuildContext context) async {
  return false;
  mypsyApi api = mypsyApi();

  String? minRequiredConfigPart;
  dynamic res = await api.getAppVersion();

  if (res != null && res is Response) {
    version = AppVersion.fromJson(res.data);
    _packageInfo = await PackageInfo.fromPlatform();
    minRequiredConfigPart = version!.data![0].attributes!.minimumBuild;
    if (minRequiredConfigPart!.isNotEmpty) {
      printConsole(
        '--- Package number ${_packageInfo.buildNumber} - MIn API $minRequiredConfigPart ',
      );
      if (int.parse(_packageInfo.buildNumber) <
          int.parse(minRequiredConfigPart)) {
        return true;
      } else {
        return false;
      }
    } // app is up to date
  } else {
    if (res != null && res is ErrorResponse) {}
    return false;
  }
  return false;
}

//check latest version required
Future<dynamic> checkOptionalUpdate(BuildContext context) async {
  return false;
  mypsyApi api = mypsyApi();
  dynamic res = await api.getAppVersion();
  String? currentAppVerison;
  if (res != null && res is Response) {
    version = AppVersion.fromJson(res.data);
    _packageInfo = await PackageInfo.fromPlatform();
    currentAppVerison = version!.data![0].attributes!.currentBuild;
    if (currentAppVerison != null && currentAppVerison.toString().isNotEmpty) {
      if (int.parse(_packageInfo.buildNumber) < int.parse(currentAppVerison)) {
        return true; //show update message with skip option
      } else {
        return false;
      }
    }
  } else {
    if (res != null && res is ErrorResponse) {}
    return false;
  }
  return false; // app is up to date
}
