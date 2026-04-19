import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/gestures.dart';
import '../services/blockchain_service.dart';
import '../user/otp.dart';
import '../user/registration_new.dart';
import '../user/home.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../admin/admin_login.dart';
import '../services/biometric_service.dart';
import 'dart:io';
import '../utils/validators.dart';


enum LoginMethod { voterId, phone, blockchain }

class LoginPageNew extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPageNew> 
  with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BlockchainService _blockchainService = BlockchainService();
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();


  final TextEditingController _phoneController = TextEditingController();
  final BiometricService _biometricService = BiometricService();




  LoginMethod _loginMethod = LoginMethod.voterId;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isWalletConnecting = false;
  bool _isWalletConnected = false;
    bool _isAuthenticating = false; // 🔥 prevent multiple calls
  bool _isAuthenticated = false;
    bool _isDialogOpen = false;

  String? _walletAddress;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _resendAttempts = 0;

  // Enhanced color scheme
  final Color primaryColor = Color(0xFF1E8449);
  final Color secondaryColor = Color(0xFF27AE60);
  final Color lightGreen = Color(0xFF2ECC71);
  final Color bgColor = Color(0xFFEBF5EE);
  final Color errorColor = Color(0xFFE74C3C);
  final Color textColor = Color(0xFF2C3E50);
  final Color lightTextColor = Color(0xFF7F8C8D);
  final Color walletConnectGreen = Color(0xFF219653); // Deep green
  final Color walletConnectLightGreen = Color(0xFF6FCF97); // Light green for gradients
  final Color walletBgColor = Color(0xFFE3F6EA); // Very light green for backgrounds

  @override
  void initState() {
    super.initState();
      WidgetsBinding.instance.addObserver(this); // 👈 ADD THIS
      _checkBiometric(); // first time check
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
    _checkWalletStatus();
  }

    Future<void> _checkBiometric() async {
    if (_isAuthenticating || _isAuthenticated) return; // 🔥 IMPORTANT

    _isAuthenticating = true;

    bool success = await _biometricService.authenticate();

    _isAuthenticating = false;


      // ✅ ADD THIS BLOCK
    if (success) {
      _isAuthenticated = true; // 🔥 THIS WAS MISSING
      print("✅ Auth success");

      // 🔥 CLOSE DIALOG IF OPEN
      if (_isDialogOpen && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _isDialogOpen = false;
      }

      return;
    }


    if (!success) {
      if (!mounted) return;

      _isDialogOpen = true;

      showDialog(
        context: context,
        barrierDismissible: false, // ❌ cannot close
        builder: (_) => AlertDialog(
          title: const Text("Authentication Required"),
          content: const Text("Please verify your identity to continue."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _isDialogOpen = false;
                // 🔥 Add delay here
                Future.delayed(const Duration(milliseconds: 300), () {
                  _checkBiometric(); // 🔁 retry again
                });
                
              },
              child: const Text("Retry"),
            ),
            TextButton(
              onPressed: () {
                exit(0); // 🔥 closes app completely
              },
              child: const Text("Exit"),
            ),
          ],
        ),
      );
    }
  }


  Future<void> _checkWalletStatus() async {
    final isConnected = await _blockchainService.isWalletConnected();
    final address = await _blockchainService.getWalletAddress();

    setState(() {
      _isWalletConnected = isConnected;
      _walletAddress = address;
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _switchLoginMethod(LoginMethod method) {
    if (_loginMethod != method) {
      setState(() {
        _loginMethod = method;
        _errorMessage = null;
        _inputController.clear();
        _passwordController.clear();
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  Future<void> logAuthAttempt({
    required String userId,
    required String method,
    required String status,
    String? phoneNumber,
    String? error,
  }) async {
    try {
      await _firestore.collection('login_attempts').add({
        'userId': userId,
        'method': method,
        'status': status,
        'timestamp': FieldValue.serverTimestamp(),
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (error != null) 'error': error,
        'platform': Theme.of(context).platform.toString(),
        'app_version': '1.0.0',
      });
    } catch (e) {
      print("Error logging auth attempt: $e");
    }
  }

  Future<void> storeUserSession({
    required String aadhaarNumber,
    String? uid,
    required String name,
    String role = 'voter',
  }) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('aadhaarNumber', aadhaarNumber);
      if (uid != null) await prefs.setString('uid', uid);
      await prefs.setString('userName', name);
      await prefs.setString('userRole', role);
      await prefs.setBool('isLoggedIn', true);

      await _firestore.collection('users').doc(aadhaarNumber).update({
        'isLoggedIn': true,
        'lastLogin': FieldValue.serverTimestamp(),
        'lastLoginDevice': Theme.of(context).platform.toString(),
        'lastLoginMethod': _loginMethod == LoginMethod.voterId ? 'voterId' :
        _loginMethod == LoginMethod.phone ? 'phone' : 'blockchain',
      });
    } catch (e) {
      print("Error storing user session: $e");
    }
  }

  Future<void> _sendOTPWithBackoff() async {
    if (_resendAttempts > 3) {
      setState(() {
        _errorMessage = "Too many attempts. Please try again later.";
        _isLoading = false;
      });
      return;
    }

    try {
      await _authService.sendOTP(_phoneController.text.trim());
    } catch (e) {
      if (e.toString().contains("too-many-requests") ||
          e.toString().contains("quota-exceeded")) {
        setState(() {
          _resendAttempts++;
          _errorMessage = "Service temporarily unavailable. Please try again later.";
          _isLoading = false;
        });
      } else {
        rethrow;
      }
    }
  }



  Future<void> _connectWallet() async {
    setState(() {
      _isWalletConnecting = true;
      _errorMessage = null;
    });

    try {
      final result = await _blockchainService.connectWallet();

      setState(() {
        _isWalletConnected = result['success'];
        _walletAddress = result['address'];
        _isWalletConnecting = false;
      });

      if (result['success']) {
        _switchLoginMethod(LoginMethod.blockchain);

        // Show a success message with animation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  'Wallet connected successfully!',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            backgroundColor: walletConnectGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        setState(() {
          _errorMessage = result['message'];
        });
      }
    } catch (e) {
      setState(() {
        _isWalletConnecting = false;
        _errorMessage = "Error connecting wallet: ${e.toString()}";
      });
    }
  }

  Future<void> _loginWithWallet() async {
    if (!_isWalletConnected || _walletAddress == null) {
      setState(() {
        _errorMessage = "Please connect your wallet first";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final securityMessage = _blockchainService.generateSecurityMessage();
      final signature = await _blockchainService.signMessage(securityMessage);

      QuerySnapshot queryResult = await _firestore
          .collection('users')
          .where('walletAddress', isEqualTo: _walletAddress)
          .limit(1)
          .get();

      if (queryResult.docs.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = "No account found with this wallet. Please register first.";
        });
        return;
      }

      final verified = await _blockchainService.verifySignature(
          securityMessage,
          signature,
          _walletAddress!
      );

      if (!verified) {
        throw Exception("Wallet signature verification failed");
      }

      final userDoc = queryResult.docs.first;
      final aadhaarNumber = userDoc.id;
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      await logAuthAttempt(
        userId: aadhaarNumber,
        method: 'blockchain_wallet',
        status: 'success',
      );

      await storeUserSession(
        aadhaarNumber: aadhaarNumber,
        name: userData['fullName'] ?? userData['name'] ?? 'Voter',
      );

      Navigator.pushReplacementNamed(
        context,
        '/home',
        arguments: aadhaarNumber,
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Wallet login failed: ${e.toString()}";
      });

      logAuthAttempt(
        userId: 'unknown',
        method: 'blockchain_wallet',
        status: 'failed',
        error: e.toString(),
      );
    }
  }

  Future<void> _loginWithVoterId() async {

    debugPrint('\x1B[32m'
    'lib/user/login.dart: _login() executed'
    '\x1B[0m');

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {

      final result = await _authService.login(
        voterId: _inputController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
        final user = _authService.currentUser;

      final _user = result.user;

    if (result.success) {

    print('\x1B[33m'
        'lib/user/login_new.dart: Login successful for user ID: ${_user!.id}'
        '\x1B[0m');


      _authService.saveLogin(_user!.id);



      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage()
          ),
      );
      } else if (result.error == 'Phone not verified') {
        if (user != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OTPVerificationPage(phone: user.phone),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Login failed'),
            backgroundColor: AppColors.error,
          ),
        );
      }

    } catch (e) {
      setState(() {
        _isLoading = false;
        if (e.toString().contains("not registered")) {
          _errorMessage = "Aadhaar number not registered in the system";
        } else if (e.toString().contains("Invalid password")) {
          _errorMessage = "Invalid password. Please try again.";
        } else {
          _errorMessage = "Login failed: ${e.toString()}";
        }
      });

      logAuthAttempt(
        userId: _inputController.text.trim(),
        method: 'aadhaar_password',
        status: 'failed',
        error: e.toString(),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _shortenWalletAddress(String address) {
    if (address.length > 12) {
      return address.substring(0, 6) + '...' + address.substring(address.length - 4);
    }
    return address;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              bgColor,
              Color(0xFFD4EBD7),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo and Title
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.how_to_vote_rounded,
                              size: 50,
                              color: primaryColor,
                            ),
                          ),
                          SizedBox(height: 30),
                          ShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [primaryColor, lightGreen],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                            child: Text(
                              'Welcome to E-Vote',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Secure blockchain-powered voting system',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: lightTextColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 40),

                    // Login method tabs with enhanced styling
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(5),
                      child: Row(
                        children: [
                          _buildLoginTab(LoginMethod.voterId, 'voterId', Icons.credit_card_rounded),
                          _buildLoginTab(LoginMethod.phone, 'Phone', Icons.phone_android_rounded),
                          _buildLoginTab(LoginMethod.blockchain, 'Wallet', Icons.account_balance_wallet_rounded),
                        ],
                      ),
                    ),
                    SizedBox(height: 35),

                    // Login form
                    AnimatedBuilder(
                      animation: _fadeAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeAnimation.value,
                          child: _buildLoginForm(),
                        );
                      },
                    ),
                    SizedBox(height: 20),



              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminLoginPage()),
                  );
                },
                child: Text(
                  'Admin Login',
                  style: TextStyle(color: primaryColor),
                ),
              ),
  


                    // Register link with improved styling
                    if (_loginMethod != LoginMethod.blockchain)
                      Center(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 15,
                              color: textColor,
                            ),
                            children: [
                              TextSpan(text: "Don't have an account? "),
                              TextSpan(
                                text: "Register",
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RegistrationPageNew(),
                                      ),
                                    );
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),
                 
                    

                    // Error message with improved styling
                    if (_errorMessage != null) ...[
                      SizedBox(height: 20),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: errorColor, size: 22),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: errorColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    SizedBox(height: 30),

                    // Security note with improved styling
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 15,
                              offset: Offset(0, 6),
                              spreadRadius: 1,
                            ),
                          ],
                          border: Border.all(color: primaryColor.withOpacity(0.1))
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.security, color: primaryColor, size: 20),
                              ),
                              SizedBox(width: 12),
                              Expanded(         
                                child: Text(
                                'Blockchain Secured Authentication',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                  fontSize: 15,
                                  letterSpacing: 0.3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              )
                            ],
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Your credentials are verified through a secure blockchain network, ensuring the highest level of security and transparency.',
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor.withOpacity(0.8),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginTab(LoginMethod method, String title, IconData icon) {
    bool isSelected = _loginMethod == method;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchLoginMethod(method),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 12,
              offset: Offset(0, 5),
              spreadRadius: 0,
            )]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : lightTextColor,
                size: 24,
              ),
              SizedBox(height: 10),
              Text(
                title,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : lightTextColor,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    switch (_loginMethod) {
      case LoginMethod.voterId:
        return _buildVoterIdLoginForm();
      case LoginMethod.phone:
        return _buildPhoneLoginForm();
      case LoginMethod.blockchain:
        return _buildBlockchainLoginForm();
    }
  }

  Widget _buildVoterIdLoginForm() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 25,
            offset: Offset(0, 10),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Login with Voter ID',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Enter your 10-digit Voter ID and password',
              style: TextStyle(
                fontSize: 14,
                color: lightTextColor,
                letterSpacing: 0.2,
              ),
            ),
            SizedBox(height: 25),

            // Voter ID input with improved styling
            TextFormField(
              controller: _inputController,
              maxLength: 10,
              decoration: InputDecoration(
                labelText: 'Voter ID',
                labelStyle: TextStyle(color: lightTextColor, fontSize: 15),
                prefixIcon: Icon(Icons.credit_card, color: primaryColor),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: errorColor),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: errorColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                counterText: "",
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              style: TextStyle(
                fontSize: 16,
                color: textColor,
                letterSpacing: 0.5,
              ),
              validator: Validators.validateVoterID,
            ),
            SizedBox(height: 22),

            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: lightTextColor, fontSize: 15),
                prefixIcon: Icon(Icons.credit_card, color: primaryColor),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: errorColor),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: errorColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                counterText: "",
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              style: TextStyle(
                fontSize: 16,
                color: textColor,
                letterSpacing: 0.5,
              ),
              validator: Validators.validateEmail,
            ),
            SizedBox(height: 22),

            // Password input with improved styling
            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              validator:Validators.validatePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: lightTextColor, fontSize: 15),
                prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                    color: lightTextColor,
                    size: 22,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: errorColor),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: errorColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              style: TextStyle(
                fontSize: 16,
                color: textColor,
              ),
            ),
            SizedBox(height: 28),

            // Login button with improved styling
            ElevatedButton(
              onPressed: _isLoading ? null : _loginWithVoterId,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              )
                  : Text(
                'Log In',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            SizedBox(height: 18),

          ],
        ),
      ),
    );
  }

  Widget _buildPhoneLoginForm() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 25,
            offset: Offset(0, 10),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Login with Phone',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Enter your registered phone number to receive OTP',
              style: TextStyle(
                fontSize: 14,
                color: lightTextColor,
                letterSpacing: 0.2,
              ),
            ),
            SizedBox(height: 25),

            // Phone input with improved styling
            TextFormField(
              controller: _inputController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                labelStyle: TextStyle(color: lightTextColor, fontSize: 15),
                prefixIcon: Icon(Icons.phone_android, color: primaryColor),
                prefixText: '+91 ',
                prefixStyle: TextStyle(
                  fontSize: 16,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: errorColor),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: errorColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                counterText: "",
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              style: TextStyle(
                fontSize: 16,
                color: textColor,
                letterSpacing: 0.5,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                if (value.length != 10 || !RegExp(r'^\d{10}$').hasMatch(value)) {
                  return 'Phone number must be exactly 10 digits';
                }
                return null;
              },
            ),
            SizedBox(height: 30),

            // Request OTP button with improved styling
            ElevatedButton(
              onPressed: _isLoading ? null : _sendOTPWithBackoff,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              )
                  : Text(
                'Request OTP',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            SizedBox(height: 25),

            // Phone info with improved styling
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Color(0xFFF1F9F1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 22,
                    color: primaryColor,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Make sure to use the same phone number you used during registration',
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockchainLoginForm() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 25,
            offset: Offset(0, 10),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Blockchain Wallet Authentication',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Connect your blockchain wallet for secure authentication',
            style: TextStyle(
              fontSize: 14,
              color: lightTextColor,
              letterSpacing: 0.2,
            ),
          ),
          SizedBox(height: 25),

          if (_isWalletConnected && _walletAddress != null)
            _buildConnectedWalletUI()
          else
            _buildConnectWalletUI(),
        ],
      ),
    );
  }

  Widget _buildConnectedWalletUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: walletBgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: walletConnectGreen.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: walletConnectGreen.withOpacity(0.1),
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: walletConnectGreen.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: walletConnectGreen,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Wallet Connected',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: walletConnectGreen,
                      fontSize: 16,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                'Your Address:',
                style: TextStyle(
                  fontSize: 14,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: walletConnectGreen.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 18,
                        color: walletConnectGreen,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _walletAddress!,
                        style: TextStyle(
                          fontSize: 13,
                          color: textColor,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 28),

        // Sign in button with improved styling
        Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: [primaryColor, walletConnectGreen, walletConnectLightGreen],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: walletConnectGreen.withOpacity(0.3),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _loginWithWallet,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            )
                : Text(
              'Sign In with Wallet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),

        SizedBox(height: 18),

        // Disconnect button with improved styling
        Center(
          child: TextButton.icon(
            onPressed: _isLoading
                ? null
                : () async {
              try {
                await _blockchainService.disconnectWallet();
                setState(() {
                  _isWalletConnected = false;
                  _walletAddress = null;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.link_off, color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'Wallet disconnected successfully',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    backgroundColor: primaryColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Error disconnecting wallet: $e',
                      style: TextStyle(),
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            icon: Icon(
              Icons.link_off,
              size: 18,
              color: Colors.red.shade700,
            ),
            label: Text(
              'Disconnect Wallet',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectWalletUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: walletBgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: walletConnectGreen.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: walletConnectGreen.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: walletConnectGreen,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Wallet Not Connected',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      fontSize: 16,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                'Connect your blockchain wallet to securely authenticate without password.',
                style: TextStyle(
                  fontSize: 14,
                  color: textColor.withOpacity(0.8),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 28),

        // Connect wallet button with improved styling
        Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: [primaryColor, walletConnectGreen, walletConnectLightGreen],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: walletConnectGreen.withOpacity(0.3),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isWalletConnecting ? null : _connectWallet,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isWalletConnecting
                ? SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_balance_wallet_rounded, size: 20),
                SizedBox(width: 10),
                Text(
                  'Connect Wallet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 25),

        // Info note with improved styling
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Color(0xFFF1F9F1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: primaryColor.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.info_outline,
                  size: 20,
                  color: primaryColor,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You need to have registered your account with a connected blockchain wallet to use this login method.',
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}