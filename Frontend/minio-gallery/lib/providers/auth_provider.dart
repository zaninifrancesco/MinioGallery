import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../services/auth_service.dart';
import '../services/token_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final TokenService _tokenService = TokenService();

  User? _user;
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _errorMessage;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get errorMessage => _errorMessage;

  // Initialize auth state
  Future<void> initializeAuth() async {
    _setLoading(true);
    try {
      final isLoggedIn = await _tokenService.isLoggedIn();
      if (isLoggedIn) {
        final user = await _tokenService.getUser();
        if (user != null) {
          _user = user;
          _isLoggedIn = true;
        } else {
          await logout();
        }
      }
    } catch (e) {
      await logout();
    }
    _setLoading(false);
  }

  // Login
  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final request = LoginRequest(username: username, password: password);
      final response = await _authService.login(request);

      await _tokenService.saveTokens(
        response.token,
        response.refreshToken,
        response.user,
      );

      _user = response.user;
      _isLoggedIn = true;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Register
  Future<bool> register(String username, String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final request = RegisterRequest(
        username: username,
        email: email,
        password: password,
      );
      final response = await _authService.register(request);

      await _tokenService.saveTokens(
        response.token,
        response.refreshToken,
        response.user,
      );

      _user = response.user;
      _isLoggedIn = true;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _setLoading(true);

    try {
      final token = await _tokenService.getToken();
      if (token != null) {
        await _authService.logout(token);
      }
    } catch (e) {
      // Continue with logout even if server call fails
    }

    await _tokenService.clearTokens();
    _user = null;
    _isLoggedIn = false;
    _clearError();
    _setLoading(false);
  }

  // Refresh user profile
  Future<void> refreshProfile() async {
    if (!_isLoggedIn) return;

    try {
      final token = await _tokenService.getToken();
      if (token != null) {
        final user = await _authService.getProfile(token);
        _user = user;
        await _tokenService.updateUser(user);
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to refresh profile');
    }
  }

  // Refresh token
  Future<bool> refreshTokens() async {
    try {
      final refreshToken = await _tokenService.getRefreshToken();
      if (refreshToken != null) {
        final response = await _authService.refreshToken(refreshToken);
        await _tokenService.saveTokens(
          response.token,
          response.refreshToken,
          response.user,
        );
        _user = response.user;
        return true;
      }
    } catch (e) {
      await logout();
    }
    return false;
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
