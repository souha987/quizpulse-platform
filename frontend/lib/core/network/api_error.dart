import 'package:dio/dio.dart';

String getErrorMessage(Object e, [String fallback = 'Une erreur est survenue']) {
  if (e is DioException && e.response?.data is Map) {
    final error = (e.response!.data as Map)['error'];
    if (error != null) {
      return error.toString();
    }
  }
  return fallback;
}

