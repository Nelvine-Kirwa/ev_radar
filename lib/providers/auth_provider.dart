import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();

  User? _user;
  bool _isLoading = false;
  String? _error;

  AuthProvider() {
    _service.authStateChanges.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isSignedIn => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> signUp({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      await _service.signUp(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _service.friendlyError(e);
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      await _service.signIn(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _service.friendlyError(e);
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _service.signOut();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}