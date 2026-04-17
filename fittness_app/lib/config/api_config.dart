import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class ApiConfig {
  static const int port = 8000;

  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:$port';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:$port';
      if (Platform.isIOS) return 'http://localhost:$port';
      return 'http://localhost:$port';
    } catch (_) {
      return 'http://localhost:$port';
    }
  }

  static const Duration timeout = Duration(seconds: 30);
  static const Duration aiTimeout = Duration(seconds: 90);
}
