import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class AppConfig {
  static const int defaultPort = 5000;
  static const String productionApiUrl = 'https://quizpulse-platform-6pfl.onrender.com/api';

  /// URL de l'API backend résolue selon les priorités suivantes :
  /// 1. Flag compilé via `--dart-define=API_URL=https://...`
  /// 2. Sur mobile en mode release ou sur smartphone réel : URL de production Render
  /// 3. Hôte dynamique sur Flutter Web (ex: http://192.168.x.x:5000/api si accédé depuis le réseau local)
  /// 4. Hôte spécial Android Emulator en mode debug (http://10.0.2.2:5000/api)
  /// 5. Hôte par défaut
  static String get defaultApiUrl {
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) return envUrl;

    // Sur application mobile installée sur smartphone (mode release), pointer vers le serveur de production
    if (!kIsWeb && kReleaseMode) {
      return productionApiUrl;
    }

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

    return productionApiUrl;
  }
}
