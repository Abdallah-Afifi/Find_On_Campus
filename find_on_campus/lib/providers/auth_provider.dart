import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  AppUser? _currentUser;
  bool _isLoading = false;
  String? _error;
  
  // Getters
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  AuthProvider() {
    // Initialize by checking current user
    _initCurrentUser();
  }
  
  // Initialize current user from auth service
  Future<void> _initCurrentUser() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      if (_authService.currentUser != null) {
        _currentUser = await _authService.getUserData();
      }
    } catch (e) {
      _error = 'Failed to initialize user: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final userCredential = await _authService.signInWithGoogle();
      
      if (userCredential != null) {
        _currentUser = await _authService.getUserData();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        _error = 'Sign in cancelled';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Sign in failed: $e';
      notifyListeners();
      return false;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _authService.signOut();
      _currentUser = null;
    } catch (e) {
      _error = 'Sign out failed: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Refresh user data
  Future<void> refreshUserData() async {
    if (_authService.currentUser == null) {
      _currentUser = null;
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      _currentUser = await _authService.getUserData();
    } catch (e) {
      _error = 'Failed to refresh user: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // Get user by ID
  Future<AppUser?> getUserById(String userId) async {
    if (userId.isEmpty) return null;
    
    try {
      return await _authService.getUserById(userId);
    } catch (e) {
      _error = 'Failed to get user: $e';
      print(_error);
      return null;
    }
  }
}