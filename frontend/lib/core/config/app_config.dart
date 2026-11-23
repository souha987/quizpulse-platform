import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class AppConfig {
  static const int defaultPort = 5000;

  /// URL de l'API backend résolue selon les priorités suivantes :
  /// 1. Flag compilé via `--dart-define=API_URL=https://...`
  /// 2. Hôte dynamique sur Flutter Web (ex: http://192.168.x.x:5000/api si accédé depuis un smartphone/tablette sur le réseau local)
  /// 3. Hôte spécial Android Emulator (http://10.0.2.2:5000/api)
  /// 4. Hôte par défaut (http://localhost:5000/api)
  static String get defaultApiUrl {
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) return envUrl;

    if (kIsWeb) {
      final origin = Uri.base.origin;
      if (Uri.base.port == 3000) {
        return '${Uri.base.scheme}://${Uri.base.host}:$defaultPort/api';
      }
      if (origin.isNotEmpty && origin != 'null') {
        return '$origin/api';
      }
      final host = Uri.base.host;
      if (host.isNotEmpty && host != 'localhost' && host != '127.0.0.1') {
        final scheme = Uri.base.scheme.isNotEmpty ? Uri.base.scheme : 'http';
        return '$scheme://$host:$defaultPort/api';
      }
    }

    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:$defaultPort/api';
    }

    return 'http://localhost:$defaultPort/api';
  }
}
