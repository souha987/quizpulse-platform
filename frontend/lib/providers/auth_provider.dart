import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../core/network/api_error.dart';
import '../core/storage/local_storage.dart';
import '../models/user_model.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? errorMessage;
  final String? registrationToken;

  AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.registrationToken,
  });

  bool get isAuthenticated => user != null;
  UserRole get role => user?.role ?? UserRole.visiteur;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? errorMessage,
    String? registrationToken,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      registrationToken: registrationToken ?? this.registrationToken,
    );
  }
}

class RegisterResult {
  final bool success;
  final bool requiresVerification;
  final String email;
  final String? registrationToken;
  final String? message;
  final String? errorMessage;

  RegisterResult({
    required this.success,
    this.requiresVerification = false,
    this.email = '',
    this.registrationToken,
    this.message,
    this.errorMessage,
  });
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState(isLoading: true)) {
    _loadUserSession();
  }

  Future<void> _loadUserSession() async {
    try {
      final token = await LocalStorage.getToken();
      final userJson = await LocalStorage.getUser();

      if (token != null && userJson != null) {
        state = AuthState(user: UserModel.fromJson(userJson), isLoading: false);
      } else {
        state = AuthState(isLoading: false);
      }
    } catch (_) {
      state = AuthState(isLoading: false);
    }
  }

  Future<bool> login(String email, String motDePasse) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await apiClient.post('/auth/login', data: {
        'email': email,
        'motDePasse': motDePasse,
      });

      final token = response.data['token'];
      final user = UserModel.fromJson(response.data['user']);

      await LocalStorage.saveToken(token);
      await LocalStorage.saveUser(user.toJson());

      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      final msg = getErrorMessage(e, 'Erreur lors de la connexion');
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    }
  }

  Future<RegisterResult> register({
    required String nom,
    required String prenom,
    required String email,
    required String motDePasse,
    required UserRole role,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await apiClient.post('/auth/register', data: {
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'motDePasse': motDePasse,
        'role': role.toServerString(),
      });

      final registrationToken = response.data['registrationToken']?.toString();
      state = state.copyWith(isLoading: false, registrationToken: registrationToken);
      return RegisterResult(
        success: true,
        requiresVerification: response.data['requiresVerification'] ?? true,
        email: email,
        registrationToken: registrationToken,
        message: response.data['message'],
      );
    } catch (e) {
      final msg = getErrorMessage(e, 'Erreur lors de l\'inscription');
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return RegisterResult(
        success: false,
        errorMessage: msg,
      );
    }
  }

  Future<bool> verifyEmail(String email, String code) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await apiClient.post('/auth/verify-email', data: {
        'email': email,
        'code': code,
        if (state.registrationToken != null) 'registrationToken': state.registrationToken,
      });

      final token = response.data['token'];
      final user = UserModel.fromJson(response.data['user']);

      await LocalStorage.saveToken(token);
      await LocalStorage.saveUser(user.toJson());

      state = state.copyWith(user: user, isLoading: false, registrationToken: null);
      return true;
    } catch (e) {
      final msg = getErrorMessage(e, 'Code de confirmation invalide ou expiré');
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    }
  }

  Future<bool> resendVerificationEmail(String email) async {
    try {
      final response = await apiClient.post('/auth/resend-verification', data: {
        'email': email,
        if (state.registrationToken != null) 'registrationToken': state.registrationToken,
      });
      final newToken = response.data['registrationToken']?.toString();
      if (newToken != null) {
        state = state.copyWith(registrationToken: newToken);
      }
      return true;
    } catch (e) {
      final msg = getErrorMessage(e, 'Impossible de renvoyer le code');
      state = state.copyWith(errorMessage: msg);
      return false;
    }
  }

  Future<void> logout() async {
    await LocalStorage.removeToken();
    state = state.copyWith(clearUser: true);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
