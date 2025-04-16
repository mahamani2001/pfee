import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';

class Device {
  static double devicePixelRatio = ui.window.devicePixelRatio;
  static ui.Size size = ui.window.physicalSize;
  static double width = size.width;
  static double height = size.height;
  static double screenWidth = width / devicePixelRatio;
  static double screenHeight = height / devicePixelRatio;
  static ui.Size screenSize = ui.Size(screenWidth, screenHeight);
  final bool? isTablet, isPhone, isIos, isAndroid, isIphoneX, isSmallTablet;
  static Device? _device;

  Device(
      {this.isTablet,
      this.isPhone,
      isSmallPhone,
      this.isIos,
      this.isAndroid,
      this.isIphoneX,
      this.isSmallTablet,});

  factory Device.get() {
    if (_device != null) return _device!;

    bool isTablet;
    bool isPhone;
    bool isSmallTablet;
    bool isIos = Platform.isIOS;
    bool isAndroid = Platform.isAndroid;
    bool isIphoneX = false;
    print('-->>> Device pixel ratio : $devicePixelRatio');
    final data = MediaQueryData.fromView(WidgetsBinding.instance.window);

    if (screenWidth >= 700 &&
        screenWidth <= 720 &&
        height >= 750 &&
        devicePixelRatio <= 2.25) {
      isSmallTablet = true;
      isTablet = false;
      isPhone = false;
    } else if (devicePixelRatio < 2 &&
        (width >= 1000 || height >= 1000) &&
        data.size.shortestSide > 600) {
      isTablet = true;
      isPhone = false;
      isSmallTablet = false;
    } else if (devicePixelRatio == 2 && (width >= 1920 || height >= 1920)) {
      isTablet = true;
      isPhone = false;
      isSmallTablet = false;
    } else {
      isTablet = false;
      isPhone = true;
      isSmallTablet = false;
    }

    if (isIos &&
        (screenHeight == 812 ||
            screenWidth == 812 ||
            screenHeight == 896 ||
            screenWidth == 896)) {
      isIphoneX = true;
    }

    return _device = Device(
        isTablet: isTablet,
        isSmallTablet: isSmallTablet,
        isPhone: isPhone,
        isAndroid: isAndroid,
        isIos: isIos,
        isIphoneX: isIphoneX,);
  }
}
