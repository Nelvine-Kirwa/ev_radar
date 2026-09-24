import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signUp({
    required String email,
    required String password,
    String? name,
    String? phone,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = cred.user?.uid;
    if (uid != null) {
      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'name': name ?? '',
        'email': email.trim(),
        'phone': phone ?? '',
        'role': 'fleet',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return cred;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) return doc.data();
    } catch (_) {}

    return {
      'uid': uid,
      'email': _auth.currentUser?.email ?? '',
      'name': _auth.currentUser?.displayName ?? '',
      'phone': '',
      'role': 'fleet',
    };
  }

  Future<void> updateUserProfile({
    required String name,
    required String phone,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not signed in');

    await _db.collection('users').doc(uid).set({
      'name': name,
      'phone': phone,
    }, SetOptions(merge: true));
  }

  Future<void> submitOperatorApplication({
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
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not signed in');

    await _db.collection('operator_applications').add({
      'uid': uid,
      'companyName': companyName,
      'companyContact': companyContact,
      'companyEmail': companyEmail,
      'latitude': latitude,
      'longitude': longitude,
      'building': building,
      'street': street,
      'county': county,
      'businessPermitNumber': businessPermitNumber,
      'chargers': chargers,
      'amenities': amenities,
      'status': 'pending',
      'submittedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> submitTechnicianApplication({
    required String fullName,
    required String idNumber,
    required String epraLicense,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not signed in');

    await _db.collection('technician_applications').add({
      'uid': uid,
      'fullName': fullName,
      'idNumber': idNumber,
      'epraLicense': epraLicense,
      'status': 'pending',
      'submittedAt': FieldValue.serverTimestamp(),
    });
  }

  String friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered. Try signing in.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}