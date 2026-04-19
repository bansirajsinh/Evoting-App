import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'utils/constants.dart';
import 'services/blockchain_service.dart';
import 'user/login.dart';
import 'user/home.dart';
import 'user/login_new.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/app_user.dart';


void main() async {

  print('\x1B[32m''lib/main.dart: main() executed''\x1B[0m');

  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  bool isLoggedIn = await checkLoginStatus();

  runApp(EVoteApp(isLoggedIn: isLoggedIn));
}

Future<bool> checkLoginStatus() async {
  final prefs = await SharedPreferences.getInstance();

  bool? isLoggedIn = prefs.getBool('isLoggedIn');
  int? loginTime = prefs.getInt('loginTime');

  if (isLoggedIn == true && loginTime != null) {
    final now = DateTime.now().millisecondsSinceEpoch;

    // ⏳ 24 hours expiry
    if (now - loginTime > 24 * 60 * 60 * 1000) {
      await prefs.remove('isLoggedIn');
      await prefs.remove('loginTime');
      return false;
    }

    return true; // still valid
  }

  return false;
}



Future<String?> getStoredUid() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('uid');
}


class EVoteApp extends StatelessWidget {


  final bool isLoggedIn;
  const EVoteApp({super.key,required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
        ),
      ),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

    final FirebaseFirestore _db = FirebaseFirestore.instance;
    final AuthService _authService = AuthService();
      AppUser? _currentUser;
    


  @override
  void initState() {
    super.initState();
    _initializeAndNavigate();
    debug();
  }

  Future<void> _initializeAndNavigate() async {
    print('\x1B[32m'
        'lib/main.dart: _initializeAndNavigate() executed'
        '\x1B[0m');

    try {
      final blockchainService = BlockchainService();
      await blockchainService.connect();
      debugPrint("✅ Blockchain connected");
    } catch (e) {
      debugPrint("❌ Blockchain connection error: $e");
    }

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;


    bool isValid = await checkLoginStatus();

    if (isValid) {
    String? uid = await getStoredUid();


    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      print('\x1B[35m''lib/main.dart: _initializeAndNavigate() user: ${uid}''\x1B[0m');

      print('\x1B[35m''lib/main.dart: _initializeAndNavigate() doc: ${doc}''\x1B[0m');

final user = AppUser.fromMap(uid, doc.data()!);

_authService.setCurrentUser(user); // 🔥 THIS IS THE FIX
      _authService.debugCurrentUser();

      


      if (doc.exists) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomePage(userData: doc.data()),
          ),
        );
        return;
      }
    }
  }else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginPageNew()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
  
  void debug(){
    debugPrint('\x1B[34m''lib/main.dart: executed''\x1B[0m');
  }
}