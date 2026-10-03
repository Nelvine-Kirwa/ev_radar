import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_vehicle.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();

  User? _user;
  Map<String, dynamic>? _profile;
  bool _isLoading = false;
  String? _error;

  AuthProvider() {
    _service.authStateChanges.listen((user) async {
      _user = user;
      if (user != null) {
        _profile = await _service.getUserProfile();
      } else {
        _profile = null;
      }
      notifyListeners();
    });
  }

  User? get user => _user;
  Map<String, dynamic>? get profile => _profile;
  bool get isSignedIn => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String get displayName {
    final n = _profile?['name'];
    if (n != null && (n as String).isNotEmpty) return n;
    return _user?.displayName ?? 'EV Fleet Member';
  }

  String get displayEmail => _profile?['email'] ?? _user?.email ?? '';
  String get displayPhone => _profile?['phone'] ?? '';

  String get role {
    final r = _profile?['role'];
    if (r is String && r.isNotEmpty) return r;
    return 'fleet';
  }

  String get roleLabel {
    switch (role) {
      case 'technician':
        return 'Electrician';
      case 'operator':
        return 'Station Operator';
      case 'user':
        return 'EV Driver';
      case 'fleet':
      default:
        return 'EV Fleet Member';
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    String? name,
    String? phone,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      await _service.signUp(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );
      _profile = await _service.getUserProfile();
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
      _profile = await _service.getUserProfile();
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
    _profile = null;
  }

  Future<bool> updateProfile({
    required String name,
    required String phone,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      await _service.updateUserProfile(name: name, phone: phone);
      _profile = await _service.getUserProfile();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> submitOperator({
    required String companyName,
    required String companyContact,
    required String companyEmail,
    required double latitude,
    required double longitude,
    required String building,
    required String street,
    required String county,
    required String businessPermitNumber,
    required List<Map<String, dynamic>> chargers,
    required List<String> amenities,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      await _service.submitOperatorApplication(
        companyName: companyName,
        companyContact: companyContact,
        companyEmail: companyEmail,
        latitude: latitude,
        longitude: longitude,
        building: building,
        street: street,
        county: county,
        businessPermitNumber: businessPermitNumber,
        chargers: chargers,
        amenities: amenities,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> submitTechnician({
    required String fullName,
    required String idNumber,
    required String epraLicense,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      await _service.submitTechnicianApplication(
        fullName: fullName,
        idNumber: idNumber,
        epraLicense: epraLicense,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<List<UserVehicle>> loadVehicles() async {
    return await _service.loadUserVehicles();
  }

  Future<int> loadCurrentVehicleIndex() async {
    return await _service.loadCurrentVehicleIndex();
  }

  Future<void> saveVehicles(
      List<UserVehicle> vehicles, int currentIndex) async {
    await _service.saveUserVehicles(vehicles, currentIndex);
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