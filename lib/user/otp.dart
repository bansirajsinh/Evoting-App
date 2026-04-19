import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import 'home.dart';
import 'registration.dart';

class OTPVerificationPage extends StatefulWidget {
  
  
  final String phone;
  final bool isRegistration;
  final Map<String, dynamic>? userData;


  const OTPVerificationPage({
    super.key,
    required this.phone,
    this.isRegistration = false,
    this.userData
  });


  @override
  State<OTPVerificationPage> createState() => _OTPVerificationPageState();

}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  // final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final _authService = AuthService();


  bool _isLoading = false;
  bool _canResend = false;
  int _resendTimer = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // _authService.sendOTP(widget.phone); // 🔥 ADD THIS
    // _startResendTimer();
    debug();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    debugPrint('\x1B[32m'
    'lib/user/otp.dart: _startResendTimer() executed'
    '\x1B[0m');
    setState(() {
      _canResend = false;
      _resendTimer = 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() => _resendTimer--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  String get _otp => _otpControllers.map((c) => c.text).join();


  Future<void> _verifyOTP() async {
    debugPrint('\x1B[32m'
    'lib/user/otp.dart: _verifyOTP() executed'
    '\x1B[0m');
    
    final otp = _otp;
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter complete OTP'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {


      final success = await _authService.verifyOTP(otp);

      if (!mounted) return;

      if (success) {

        // 🔥 IF REGISTER FLOW → CREATE USER NOW
        if (widget.isRegistration && widget.userData != null) {

          final registerResult = await _authService.register(
            name: widget.userData!["name"],
            password: widget.userData!["password"],
            dateOfBirth: widget.userData!["dob"],
            voterId: widget.userData!["voterId"],
            aadhaar: widget.userData!["aadhaar"],
            email: widget.userData!["email"],
            phone: widget.userData!["phone"],
            address: widget.userData!["address"],
            state: widget.userData!["state"],
            district: widget.userData!["district"],
            constituency: widget.userData!["constituency"],
          );

          if (!registerResult.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(registerResult.error ?? "Registration failed")),
            );
            return;
          }
        }

        // ✅ GO TO HOME
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );

      }else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP failed')),
      );

      // 🔥 If login failed → go to register
      if (!widget.isRegistration) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RegistrationPage()),
        );
      }
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

  Future<void> _resendOTP() async {
    debugPrint('\x1B[32m'
    'lib/user/otp.dart: _resendOTP() executed'
    '\x1B[0m');
    if (!_canResend) return;

    try {
      await _authService.resendOTP(phone: widget.phone);
      _startResendTimer();
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP sent successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to resend OTP: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Verify Phone'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.message_outlined,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                AppStrings.otpTitle,
                style: AppTextStyles.heading2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'We have sent a 6-digit OTP to\n${widget.phone}',
                style: AppTextStyles.body2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 45,
                    height: 55,
                    child: TextFormField(
                      controller: _otpControllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimens.borderRadiusSmall),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                        if (index == 5 && value.isNotEmpty) {
                          _verifyOTP();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: AppDimens.buttonHeight,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.borderRadius),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Verify OTP', style: AppTextStyles.button),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Didn't receive OTP? "),
                  TextButton(
                    onPressed: _canResend ? _resendOTP : null,
                    child: Text(
                      _canResend ? 'Resend OTP' : 'Resend in ${_resendTimer}s',
                      style: TextStyle(
                        color: _canResend ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
  
  void debug() {
  debugPrint('\x1B[34m'
      'lib/user/otp.dart: executed'
      '\x1B[0m');
  }
}
