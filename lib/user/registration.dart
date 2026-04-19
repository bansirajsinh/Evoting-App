import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import 'otp.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _voterIdController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  
  String? _selectedConstituency;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;

  final List<String> _constituencies = [
    'Central Delhi',
    'North Delhi',
    'South Delhi',
    'East Delhi',
    'West Delhi',
    'New Delhi',
    'Chandni Chowk',
    'Northeast Delhi',
    'Northwest Delhi',
    'Shahdara',
  ];

  @override
  void initState() {
    super.initState();
    debug();   // 👈 will run when this screen is created
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dateOfBirthController.dispose();
    _voterIdController.dispose();
    _aadhaarController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {

    debugPrint('\x1B[32m'
    'lib/user/registration.dart: _register() executed'
    '\x1B[0m');

    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Accept terms first')),
      );
      return;
    }

    // 🚀 ONLY GO TO OTP (NO USER CREATION)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OTPVerificationPage(
          
          phone: "+91${_phoneController.text.trim()}",
          isRegistration: true,
          userData: {
            "name": _nameController.text.trim(),
            "password": _passwordController.text,
            "dob": _dateOfBirthController.text,
            "voterId": _voterIdController.text.trim(),
            "aadhaar": _aadhaarController.text.replaceAll(' ', ''),
            "email": _emailController.text.trim(),
            "phone": _phoneController.text.trim(),
            "address": _addressController.text.trim(),
            "constituency": _selectedConstituency!,
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  AppStrings.registerTitle,
                  style: AppTextStyles.heading2,
                ),
                const SizedBox(height: 8),
                const Text(
                  AppStrings.registerSubtitle,
                  style: AppTextStyles.body2,
                ),
                const SizedBox(height: 32),
                
                TextFormField(
                  controller: _nameController,
                  validator: Validators.validateName,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: const Icon(Icons.person_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimens.borderRadius),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _dateOfBirthController,
                  readOnly: true, // user can't type manually
                  // validator: Validators.dateOfBirthValidator,
                  decoration: InputDecoration(
                    labelText: 'Date of Birth',
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                    hintText: 'Select your date of birth',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimens.borderRadius),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime(2000),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );

                    if (pickedDate != null) {
                      setState(() {
                        _dateOfBirthController.text =
                            "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _voterIdController,
                  // validator: Validators.validateVoterID,
                  // maxLength: 10,
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
                  controller: _aadhaarController,
                  keyboardType: TextInputType.number,
                  validator: Validators.validateAadhaar,
                  maxLength: 12,
                  decoration: InputDecoration(
                    labelText: 'Aadhaar Number',
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
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: Validators.validatePhone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    hintText: '+91XXXXXXXXXX',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimens.borderRadius),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _addressController,
                  keyboardType: TextInputType.multiline,
                  validator: Validators.addressValidator,
                  maxLines: 3, // allows multiple lines
                  decoration: InputDecoration(
                    labelText: 'Address',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    hintText: 'Enter your full address',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimens.borderRadius),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
        
                DropdownButtonFormField<String>(
                  initialValue: _selectedConstituency,
                  validator: (value) => Validators.validateConstituency(value),
                  decoration: InputDecoration(
                    labelText: 'Constituency',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimens.borderRadius),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: _constituencies.map((constituency) {
                    return DropdownMenuItem(
                      value: constituency,
                      child: Text(constituency),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedConstituency = value);
                  },
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  validator: Validators.validatePassword,
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
                    helperText: 'Min 8 chars with uppercase, lowercase, and number',
                    helperMaxLines: 2,
                  ),
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  validator: (value) => Validators.validateConfirmPassword(
                    value,
                    _passwordController.text,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimens.borderRadius),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                
                CheckboxListTile(
                  value: _acceptTerms,
                  onChanged: (value) => setState(() => _acceptTerms = value ?? false),
                  title: const Text(
                    'I accept the Terms of Service and Privacy Policy',
                    style: TextStyle(fontSize: 14),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.primary,
                ),
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  height: AppDimens.buttonHeight,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimens.borderRadius),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Register', style: AppTextStyles.button),
                  ),
                ),
                const SizedBox(height: 16),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? '),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void debug() {
  debugPrint('\x1B[34m'
      'lib/user/registration.dart: executed'
      '\x1B[0m');
  }
}
