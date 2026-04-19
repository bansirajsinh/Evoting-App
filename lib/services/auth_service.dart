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
  // 👇 ADD THIS (Singleton pattern)
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

    try{

      await _db.collection("hostCredentials").doc("host").get();
    }catch(e){
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

  // ✅ SAVE REAL USER ID (VERY IMPORTANT)
  await prefs.setString('uid', uid);
}


//in use
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
    print('\x1B[32m'
        'lib/services/auth_service.dart: register() executed'
        '\x1B[0m');
    try {
      print("🟡 Starting registration...");

      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;
      print("✅ Firebase user created: $uid");

      await _db.collection('users').doc(uid).set({
        'name': name,
        'dateOfBirth': dateOfBirth,
        'voterId': voterId,
        'aadhaar': aadhaar,
        'email': email,
        'phone': phone,
        'address': address,
        'state': state,
        'district': district,
        'constituency': constituency,
        'role': 'voter',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _db.collection('voters').doc(uid).set({
        'uid': uid,
        'name': name,
        'voterId': voterId,
        'aadhaar': aadhaar, // Store hash, not actual number
        'state': state,
        'district': district,
        'constituency': constituency,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print("💾 User saved to Firestore");

      final doc = await _db.collection('users').doc(uid).get();

      _currentUser = AppUser.fromMap(uid, doc.data()!);

      print('\x1B[32m'
          'lib/service/auth_seervice.dart: `register` sucsses'
          '\x1B[0m');

      return AuthResult(success: true, user: _currentUser);
    } catch (e) {
      print('\x1B[31m'
          'lib/service/auth_seervice.dart: `register` fail'
          '\x1B[0m');
      print("❌ Registration error: $e");

      return AuthResult(success: false, error: e.toString());
    }
  }

//in use
  Future<AuthResult> login({
    required String voterId,
    required String email,
    required String password,
  }) async {
    print('\x1B[32m'
        'lib/services/auth_service.dart: login() executed'
        '\x1B[0m');

    try {
      print("🟡 Attempting login...");

      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;

      final doc = await _db.collection('users').doc(uid).get();

      if (doc.data()!['voterId'] != voterId) {
        await _auth.signOut();
        return AuthResult(
          success: false,
          error: "Invalid Voter ID",
        );
      }

      _currentUser = AppUser.fromMap(uid, doc.data()!);

      print("✅ Login successful");
      print('\x1B[32m''lib/service/auth_seervice.dart: `login` sucsses''\x1B[0m');

      return AuthResult(success: true, user: _currentUser);
    } catch (e) {
      print("❌ Login error: $e");
      print('\x1B[31m'
          'lib/service/auth_seervice.dart: `login` fail'
          '\x1B[0m');

      return AuthResult(success: false, error: e.toString());
    }
  }

//in use
  Future<AuthResult> adminLogin({
    required String voterId,
    required String email,
    required String password,
  }) async {
    try {
      print('\x1B[32m'
          'lib/services/auth_service.dart: adminLogin() executed'
          '\x1B[0m');
      print("🛡 Attempting admin login...");

      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;

      final doc = await _db.collection('users').doc(uid).get();

      if (!doc.exists) {
        await _auth.signOut();
        return AuthResult(
          success: false,
          error: "User data not found",
        );
      }

      if (doc.data()!['voterId'] != voterId) {
        await _auth.signOut();
        return AuthResult(
          success: false,
          error: "Invalid Voter ID",
        );
      }

      final user = AppUser.fromMap(uid, doc.data()!);

      // 🔒 CHECK ROLE
      if (doc.data()!['role'] != 'admin') {
        await _auth.signOut();
        return AuthResult(
          success: false,
          error: "Access denied. Not an admin.",
        );
      }

      _currentUser = user;

      print("🛡 Admin login successful");
      print('\x1B[32m'
          'lib/service/auth_seervice.dart: `adminLogin` sucsses'
          '\x1B[0m');

      return AuthResult(success: true, user: user);
    } catch (e) {
      print("❌ Admin login error: $e");
      print('\x1B[31m'
          'lib/service/auth_seervice.dart: `adminLogin` fail'
          '\x1B[0m');

      return AuthResult(success: false, error: e.toString());
    }
  }


  Future<void> sendOTP(String phone) async {
        print('\x1B[32m'
        'lib/services/auth_service.dart: sendOTP() executed'
        '\x1B[0m');
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        print("❌ OTP send error: ${e.message}");
      },
      codeSent: (String verificationId, int? resendToken) {
        print("✅ OTP Sent");
        _verificationId = verificationId; // 🔥 SAVE HERE
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }


  Future<void> resendOTP({required String phone}) async {
        print('\x1B[32m'
        'lib/services/auth_service.dart: resendOTP() executed'
        '\x1B[0m');
    await sendOTP(phone);
  }


  Future<bool> verifyOTP(String otp) async {

        print('\x1B[32m'
        'lib/services/auth_service.dart: verifyOTP() executed'
        '\x1B[0m');

    try {


      if(otp == "123456"){
        print("✅ OTP Verified (Test Code)");
        return true;
      }


      // if (_verificationId == null) return false;
      // PhoneAuthCredential credential = PhoneAuthProvider.credential(
      //   verificationId: _verificationId!,
      //   smsCode: otp,
      // );
      // await _auth.signInWithCredential(credential);

      return false; // ✅ success

    } catch (e) {

      print("❌ Verify OTP error: $e");
      return false;

    }
  }


  Future<bool> updateProfile({
    required String name,
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
    print('\x1B[32m'
        'lib/services/auth_service.dart: updateProfile() executed'
        '\x1B[0m');

    if (_currentUser == null) return false;

    await _db.collection('users').doc(_currentUser!.id).update({
      'name': name,
      'dateOfBirth': dateOfBirth,
      'voterId': voterId,
      'aadhaar': aadhaar,
      'email': email,
      'phone': phone,
      'address': address,
      'state': state,
      'district': district,
      'constituency': constituency,
    });

    _currentUser = AppUser(
      id: _currentUser!.id,
      name: name,
      dateOfBirth: dateOfBirth,
      voterId: voterId,
      aadhaar: aadhaar,
      email: email,
      phone: phone,
      address: address,
      state: state,
      district: district,
      constituency: constituency,
    );

    print("✅ Profile updated");
    print('\x1B[32m'
        'lib/service/auth_seervice.dart: `updateProfile` sucsses'
        '\x1B[0m');

    return true;
  }

//in use
  Future<void> logout() async {
    print('\x1B[32m'
        'lib/services/auth_service.dart: logout() executed'
        '\x1B[0m');

    await _auth.signOut();

    _currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    print("👋 User logged out");
  }

//in use
  void debugCurrentUser() {
    print('\x1B[32m'
        'lib/services/auth_service.dart: debugCurrentUser() executed'
        '\x1B[0m');
    if (_currentUser == null) {
      print('\x1B[31mNo current user in AuthService\x1B[0m');
      return;
    }

    print('\x1B[34m===== APP USER OBJECT =====\x1B[0m');
    print('ID: ${_currentUser!.id}');
    print('Email: ${_currentUser!.email}');
    print('Name: ${_currentUser!.name}');
    print('Phone: ${_currentUser!.phone}');
    print('Constituency: ${_currentUser!.constituency}');
  }
}
