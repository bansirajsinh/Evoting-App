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
  const LoginPageNew({super.key});

  @override
  State<LoginPageNew> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPageNew> 
  with WidgetsBindingObserver, SingleTickerProviderStateMixin {


  final _formKey = GlobalKey<FormState>();
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
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
  final Color primaryColor = const Color(0xFF1E8449);
  final Color secondaryColor = const Color(0xFF27AE60);
  final Color lightGreen = const Color(0xFF2ECC71);
  final Color bgColor = const Color(0xFFEBF5EE);
  final Color errorColor = const Color(0xFFE74C3C);
  final Color textColor = const Color(0xFF2C3E50);
  final Color lightTextColor = const Color(0xFF7F8C8D);
  final Color walletConnectGreen = const Color(0xFF219653); // Deep green
  final Color walletConnectLightGreen = const Color(0xFF6FCF97); // Light green for gradients
  final Color walletBgColor = const Color(0xFFE3F6EA); // Very light green for backgrounds

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
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
      debugPrint("✅ Auth success");

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
    final isConnected = _blockchainService.isConnected;
    final address = _blockchainService.walletAddress;

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
    _emailController.dispose();
    _phoneController.dispose();
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
      debugPrint("Error logging auth attempt: $e");
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
      debugPrint("Error storing user session: $e");
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
      final success = await _blockchainService.connect();

      setState(() {
        _isWalletConnected = success;
        _walletAddress = _blockchainService.walletAddress;
        _isWalletConnecting = false;
      });

      if (success) {
        _switchLoginMethod(LoginMethod.blockchain);

        if (!mounted) return;
        // Show a success message with animation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                const Text(
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
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        setState(() {
          _errorMessage = "Failed to connect wallet";
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
      // Wallet login simplified for demo as actual signMessage/verifySignature 
      // depends on the specific blockchain provider implementation.
      
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

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
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
        final user = result.user;

    if (result.success && user != null) {

    debugPrint('\x1B[33m'
        'lib/user/login_new.dart: Login successful for user ID: ${user.id}'
        '\x1B[0m');


      _authService.saveLogin(user.id);



      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomePage()
          ),
      );
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
              const Color(0xFFD4EBD7),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
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
                                  color: primaryColor.withValues(alpha: 0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.how_to_vote_rounded,
                              size: 50,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 30),
                          ShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [primaryColor, lightGreen],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                            child: const Text(
                              'Welcome to E-Vote',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
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
                    const SizedBox(height: 40),

                    // Login method tabs with enhanced styling
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(5),
                      child: Row(
                        children: [
                          _buildLoginTab(LoginMethod.voterId, 'voterId', Icons.credit_card_rounded),
                          _buildLoginTab(LoginMethod.phone, 'Phone', Icons.phone_android_rounded),
                          _buildLoginTab(LoginMethod.blockchain, 'Wallet', Icons.account_balance_wallet_rounded),
                        ],
                      ),
                    ),
                    const SizedBox(height: 35),

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
                    const SizedBox(height: 20),



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
                              const TextSpan(text: "Don't have an account? "),
                              const TextSpan(text: "Registration managed by Commission", style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                            ],
                          ),
                        ),
                      ),
                 
                    

                    // Error message with improved styling
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: errorColor, size: 22),
                            const SizedBox(width: 12),
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

                    const SizedBox(height: 30),

                    // Security note with improved styling
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                              spreadRadius: 1,
                            ),
                          ],
                          border: Border.all(color: primaryColor.withValues(alpha: 0.1))
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.security, color: primaryColor, size: 20),
                              ),
                              const SizedBox(width: 12),
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
                          const SizedBox(height: 12),
                          Text(
                            'Your credentials are verified through a secure blockchain network, ensuring the highest level of security and transparency.',
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor.withValues(alpha: 0.8),
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
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [BoxShadow(
              color: primaryColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 5),
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
              const SizedBox(height: 10),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 25,
            offset: const Offset(0, 10),
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
            const SizedBox(height: 8),
            Text(
              'Enter your 10-digit Voter ID and password',
              style: TextStyle(
                fontSize: 14,
                color: lightTextColor,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 25),

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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              style: TextStyle(
                fontSize: 16,
                color: textColor,
                letterSpacing: 0.5,
              ),
              validator: Validators.validateVoterID,
            ),
            const SizedBox(height: 22),

            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: lightTextColor, fontSize: 15),
                prefixIcon: Icon(Icons.email, color: primaryColor),
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              style: TextStyle(
                fontSize: 16,
                color: textColor,
                letterSpacing: 0.5,
              ),
              validator: Validators.validateEmail,
            ),
            const SizedBox(height: 22),

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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              style: TextStyle(
                fontSize: 16,
                color: textColor,
              ),
            ),
            const SizedBox(height: 28),

            // Login button with improved styling
            ElevatedButton(
              onPressed: _isLoading ? null : _loginWithVoterId,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              )
                  : const Text(
                'Log In',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 18),

          ],
        ),
      ),
    );
  }

  Widget _buildPhoneLoginForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 25,
            offset: const Offset(0, 10),
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
            const SizedBox(height: 8),
            Text(
              'Enter your registered phone number to receive OTP',
              style: TextStyle(
                fontSize: 14,
                color: lightTextColor,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 25),

            // Phone input with improved styling
            TextFormField(
              controller: _phoneController,
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
            const SizedBox(height: 30),

            // Request OTP button with improved styling
            ElevatedButton(
              onPressed: _isLoading ? null : _sendOTPWithBackoff,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              )
                  : const Text(
                'Request OTP',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 25),

            // Phone info with improved styling
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F9F1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 22,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 12),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 25,
            offset: const Offset(0, 10),
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
          const SizedBox(height: 8),
          Text(
            'Connect your blockchain wallet for secure authentication',
            style: TextStyle(
              fontSize: 14,
              color: lightTextColor,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 25),

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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: walletBgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: walletConnectGreen.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: walletConnectGreen.withValues(alpha: 0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: walletConnectGreen.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: walletConnectGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
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
              const SizedBox(height: 16),
              Text(
                'Your Address:',
                style: TextStyle(
                  fontSize: 14,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: walletConnectGreen.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 18,
                        color: walletConnectGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
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

        const SizedBox(height: 28),

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
                color: walletConnectGreen.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
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
                ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            )
                : const Text(
              'Sign In with Wallet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),

        const SizedBox(height: 18),

        // Disconnect button with improved styling
        Center(
          child: TextButton.icon(
            onPressed: _isLoading
                ? null
                : () async {
              try {
                // Simplified disconnect for demo
                setState(() {
                  _isWalletConnected = false;
                  _walletAddress = null;
                });
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: walletBgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: walletConnectGreen.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: walletConnectGreen.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: walletConnectGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
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
              const SizedBox(height: 12),
              Text(
                'Connect your blockchain wallet to securely authenticate without password.',
                style: TextStyle(
                  fontSize: 14,
                  color: textColor.withValues(alpha: 0.8),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

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
                color: walletConnectGreen.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
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
                ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            )
                : const Row(
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

        const SizedBox(height: 25),

        // Info note with improved styling
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F9F1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
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
              const SizedBox(width: 12),
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
