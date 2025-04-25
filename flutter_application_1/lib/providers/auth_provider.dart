import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _currentUser;
  bool _isLoading = false;
  String _error = '';

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  String get error => _error;

  AuthProvider() {
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _currentUser = await _authService.getCurrentUser();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      _currentUser = (await _authService.login(username, password, SocketService()));
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String username, String email, String password) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      await _authService.register(username, email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    
    await _authService.logout(SocketService());
    _currentUser = null;
    
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }
}

extension on AuthService {
  getCurrentUser() {}
}

extension on User? {
  get isAdmin => null;
}