import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../services/auth_service.dart';
import 'registration.dart';
import 'otp.dart';
import 'home.dart';
import '../admin/admin_login.dart';
import '../services/biometric_service.dart';
import 'dart:io';
import '../user/registration_new.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
  with WidgetsBindingObserver {



  final _formKey = GlobalKey<FormState>();
  final _voterIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final BiometricService _biometricService = BiometricService();
  

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isAuthenticating = false; // 🔥 prevent multiple calls
  bool _isAuthenticated = false;
  bool _isDialogOpen = false;
  


  @override
  void initState() {
    super.initState();
      WidgetsBinding.instance.addObserver(this); // 👈 ADD THIS
      _checkBiometric(); // first time check
    debug();   // 👈 will run when this screen is created
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isAuthenticated) {
    _checkBiometric(); // only if NOT authenticated
    }

    if (state == AppLifecycleState.paused) {
      _isAuthenticated = false; // 🔒 lock again
    }

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


  Future<void> _login() async {


    debugPrint('\x1B[32m'
    'lib/user/login.dart: _login() executed'
    '\x1B[0m');


    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await _authService.login(
        voterId: _voterIdController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (result.success) {
        _authService.debugCurrentUser();
      }

      if (!mounted) return;

      if (result.success) {

        _authService.saveLogin(result.user!.id);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomePage()
            ),
        );
      } else if (result.error == 'Phone not verified') {
        final user = _authService.currentUser;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.how_to_vote,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                AppStrings.appName,
                style: AppTextStyles.heading1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                AppStrings.tagline,
                style: AppTextStyles.body2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              const Text(
                AppStrings.loginTitle,
                style: AppTextStyles.heading2,
              ),
              const SizedBox(height: 8),
              const Text(
                AppStrings.loginSubtitle,
                style: AppTextStyles.body2,
              ),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  children: [

                    TextFormField(
                      controller: _voterIdController,
                      validator: Validators.validateVoterID,
                      maxLength: 10,
                      decoration: InputDecoration(
                        labelText: 'Voter ID Number',
                        prefixIcon: const Icon(Icons.credit_card_outlined),
                        hintText: 'XXXX XXXX XXXX',
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimens.borderRadius),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),


                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.validateEmail,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimens.borderRadius),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),


                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      validator: (value) => value?.isEmpty == true ? 'Password is required' : null,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimens.borderRadius),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),


                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: AppDimens.buttonHeight,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimens.borderRadius),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Login', style: AppTextStyles.button),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => RegistrationPageNew()),
                      );
                    },
                    child: const Text(
                      'Register',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminLoginPage()),
                  );
                },
                child: const Text(
                  'Admin Login',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void debug() {
    debugPrint('\x1B[34m'
        'lib/user/login.dart: executed'
        '\x1B[0m');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // 👈 ADD THIS
    _voterIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

}