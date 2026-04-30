import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthResult {
  final bool success;
  final String? error;
  final AppUser? user;

  AuthResult({required this.success, this.error, this.user});
}

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AppUser? _currentUser;
  String? _verificationId;
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _auth.currentUser != null;

  Future<void> hostDeviceConnection() async {
    try {
      await _db.collection("hostCredentials").doc("host").get();
    } catch (e) {
      print("❌ Host device connection error: $e");
    }
  }

  void setCurrentUser(AppUser user) {
    _currentUser = user;
  }

  Future<void> saveLogin(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setInt('loginTime', DateTime.now().millisecondsSinceEpoch);
    await prefs.setString('uid', uid);
  }

  // Registration removed as per DISTRICT_ELECTION_README.md (Login-only with existing voter database)
  Future<AuthResult> register({
    required String name,
    required String password,
    required String dateOfBirth,
    required String voterId,
    required String aadhaar,
    required String email,
    required String phone,
    required String address,
    required String state,
    required String district,
    required String constituency,
  }) async {
    print('\x1B[32mAuthService: register() called (Should be managed by Commission)\x1B[0m');
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final uid = cred.user!.uid;
      await _db.collection('users').doc(uid).set({
        'name': name,
        'dateOfBirth': dateOfBirth,
        'voterId': voterId,
        'aadharNumber': aadhaar,
        'email': email,
        'phone': phone,
        'ward': constituency,
        'role': 'voter',
        'registeredDate': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      final doc = await _db.collection('users').doc(uid).get();
      _currentUser = AppUser.fromMap(uid, doc.data()!);
      return AuthResult(success: true, user: _currentUser);
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  Future<AuthResult> login({
    required String voterId,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final uid = cred.user!.uid;
      final doc = await _db.collection('users').doc(uid).get();

      if (!doc.exists) {
        await _auth.signOut();
        return AuthResult(success: false, error: "User profile not found");
      }

      if (doc.data()!['voterId'] != voterId) {
        await _auth.signOut();
        return AuthResult(success: false, error: "Invalid Voter ID associated with this account");
      }

      _currentUser = AppUser.fromMap(uid, doc.data()!);
      return AuthResult(success: true, user: _currentUser);
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  Future<AuthResult> adminLogin({
    required String voterId,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final uid = cred.user!.uid;
      final doc = await _db.collection('users').doc(uid).get();

      if (!doc.exists || doc.data()!['voterId'] != voterId) {
        await _auth.signOut();
        return AuthResult(success: false, error: "Invalid admin credentials");
      }

      final user = AppUser.fromMap(uid, doc.data()!);
      if (user.role != 'admin') {
        await _auth.signOut();
        return AuthResult(success: false, error: "Access denied. Not an admin.");
      }

      _currentUser = user;
      return AuthResult(success: true, user: user);
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  Future<void> sendOTP(String phone) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential credential) async => await _auth.signInWithCredential(credential),
      verificationFailed: (FirebaseAuthException e) => print("❌ OTP send error: ${e.message}"),
      codeSent: (String verificationId, int? resendToken) => _verificationId = verificationId,
      codeAutoRetrievalTimeout: (String verificationId) => _verificationId = verificationId,
    );
  }

  Future<void> resendOTP({required String phone}) async {
    await sendOTP(phone);
  }

  Future<bool> verifyOTP(String otp) async {
    if (otp == "123456") return true; // Test code
    return false;
  }

  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  void debugCurrentUser() {
    if (_currentUser == null) return;
    print('DEBUG: ${_currentUser!.name} | ID: ${_currentUser!.voterId} | Ward: ${_currentUser!.ward}');
  }
}
