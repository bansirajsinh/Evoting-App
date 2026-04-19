import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/blockchain_service.dart';
import '../services/firestore_service.dart';
import 'package:flutter/gestures.dart';
import 'otp.dart';
import '../utils/validators.dart';
import '../utils/constants.dart';

class RegistrationPageNew extends StatefulWidget {
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPageNew>
  with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BlockchainService _blockchainService = BlockchainService();
  final _firestoreService = FirestoreService();


  // Animation controller
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  // Step indicator
  int _currentStep = 0;
  final int _totalSteps = 3;

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  final TextEditingController _voterIdController = TextEditingController();
  final TextEditingController _aadhaarController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();

  DateTime? _selectedDate;
  bool _acceptTerms = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool isVoterIdAlreadyUsed = false;
  bool isAadhaarAlreadyUsed = false;
  bool isEmailAlreadyUsed = false;



  // Blockchain wallet variables
  bool _isWalletConnecting = false;
  bool _isWalletConnected = false;
  String? _walletAddress;
  String? _selectedConstituency;
  String? _selectedState;
  String? _selectedDistrict;

  // Color scheme
  final Color primaryColor = Color(0xFF1E8449);
  final Color secondaryColor = Color(0xFF27AE60);
  final Color accentColor = Color(0xFF2ECC71);
  final Color backgroundColor = Color(0xFFEBF5EE);
  final Color errorColor = Color(0xFFE74C3C);
  final Color textColor = Color(0xFF2C3E50);
  final Color lightTextColor = Color(0xFF7F8C8D);


  final List<String> _constituencies = [
    'Bhavnagar city',
    'Talaja',
    'Gariadhar',
    'Sihor',
    'Ghogha',
    'Mahuva',
    'Palitana',
    'Jesar',
    'Umrala',
    'Vallabhipur',
  ];

      final Map<String, Map<String, List<String>>> locationData = {
  
  'Andhra Pradesh':{},
  'Arunachal Pradesh':{},
  'Assam':{},
  'Bihar':{},
  'Chhattisgarh':{},
  'Goa':{},
  'Gujarat': {
    'Bhavnagar': [
      'Bhavnagar city',
      'Talaja',
      'Gariadhar',
      'Sihor',
      'Ghogha',
      'Mahuva',
      'Palitana',
      'Jesar',
      'Umrala',
      'Vallabhipur',
    ],
    'Ahmedabad': [],
    'Amreli':[],
    'Anand':[],
    'Aravalli':[],
    'Banaskantha':[],
    'Bharuch':[],
    'Botad':[],
    'Chhota Udaipur':[],
    'Dahod':[],
    'Dang':[],
    'Devbhoomi Dwarka':[],
    'Gandhinagar':[],
    'Gir Somnath':[],
    'Jamnagar':[],
    'Junagadh':[],
    'Kheda':[],
    'Kutch':[],
    'Mahisagar':[],
    'Mehsana':[],
    'Morbi':[],
    'Narmada':[],
    'Navsari':[],
    'Panchmahal':[],
    'Patan':[],
    'Porbandar':[],
    'Rajkot':[],
    'Sabarkantha':[],
    'Surat':[],
    'Surendranagar':[],
    'Tapi':[],
    'Vadodara':[],
    'Valsad':[],
  },
  'Haryana':{},
  'Himachal Pradesh':{},
  'Jharkhand':{},
  'Karnataka':{},
  'Kerala':{},
  'Madhya Pradesh':{},
  'Maharashtra':{},
  'Manipur':{},
  'Meghalaya':{},
  'Mizoram':{},
  'Nagaland':{},
  'Odisha':{},
  'Punjab':{},
  'Rajasthan':{},
  'Sikkim':{},
  'Tamil Nadu':{},
  'Telangana':{},
  'Tripura':{},
  'Uttar Pradesh':{},
  'Uttarakhand':{},
  'West Bengal':{},

  // Union Territories
  'Andaman and Nicobar Islands':{},
  'Chandigarh':{},
  'Dadra and Nagar Haveli and Daman and Diu':{},
  'Delhi':{},
  'Jammu and Kashmir':{},
  'Ladakh':{},
  'Lakshadweep':{},
  'Puducherry':{}
};

    final List<String> _states = [
  'Andhra Pradesh',
  'Arunachal Pradesh',
  'Assam',
  'Bihar',
  'Chhattisgarh',
  'Goa',
  'Gujarat',
  'Haryana',
  'Himachal Pradesh',
  'Jharkhand',
  'Karnataka',
  'Kerala',
  'Madhya Pradesh',
  'Maharashtra',
  'Manipur',
  'Meghalaya',
  'Mizoram',
  'Nagaland',
  'Odisha',
  'Punjab',
  'Rajasthan',
  'Sikkim',
  'Tamil Nadu',
  'Telangana',
  'Tripura',
  'Uttar Pradesh',
  'Uttarakhand',
  'West Bengal',

  // Union Territories
  'Andaman and Nicobar Islands',
  'Chandigarh',
  'Dadra and Nagar Haveli and Daman and Diu',
  'Delhi',
  'Jammu and Kashmir',
  'Ladakh',
  'Lakshadweep',
  'Puducherry',
];

    final List<String> _gujaratDistricts = [
  'Ahmedabad',
  'Amreli',
  'Anand',
  'Aravalli',
  'Banaskantha',
  'Bharuch',
  'Bhavnagar',
  'Botad',
  'Chhota Udaipur',
  'Dahod',
  'Dang',
  'Devbhoomi Dwarka',
  'Gandhinagar',
  'Gir Somnath',
  'Jamnagar',
  'Junagadh',
  'Kheda',
  'Kutch',
  'Mahisagar',
  'Mehsana',
  'Morbi',
  'Narmada',
  'Navsari',
  'Panchmahal',
  'Patan',
  'Porbandar',
  'Rajkot',
  'Sabarkantha',
  'Surat',
  'Surendranagar',
  'Tapi',
  'Vadodara',
  'Valsad',
];



  @override
  void initState() {
    super.initState();
      _passwordController.addListener(() {
    setState(() {}); // 🔥 rebuild UI on every keystroke
  });
  _confirmPasswordController.addListener(() {
    setState(() {});
  });
    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _animController.forward();
    _checkWalletStatus();
        debug(); 
  }


voterIdCheck() async{

        print('\x1b[32m'"lib/user/registration_new.dart:  voterIdCheckVot() Executed!"'\x1b[0m');

  
    isVoterIdAlreadyUsed = await _firestoreService.isAlreadyRegisteredVoterId(_voterIdController.text);

}


aadhaarCheck() async{

    print('\x1b[32m'"lib/user/registration_new.dart:  aadhaarCheck() Executed!"'\x1b[0m');

  
    isAadhaarAlreadyUsed = await _firestoreService.isAlreadyRegisteredAadhaar(_aadhaarController.text);

}


emailCheck() async{

    print('\x1b[32m'"lib/user/registration_new.dart:  emailCheck() Executed!"'\x1b[0m');

  
    isEmailAlreadyUsed = await _firestoreService.isAlreadyRegisteredEmail(_emailController.text);

}


//funtion
  Future<void> _checkWalletStatus() async {
    final isConnected = await _blockchainService.connect();
    final address = await _blockchainService.getWalletAddress();
    setState(() {
      _isWalletConnected = isConnected;
      _walletAddress = address;
    });
  }


//funtion
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wallet connected successfully!',
            style: TextStyle()
            ),
            backgroundColor: primaryColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        setState(() => _errorMessage = result['message']);
      }
    } catch (e) {
      setState(() {
        _isWalletConnecting = false;
        _errorMessage = "Error connecting wallet: ${e.toString()}";
      });
    }
  }

//funtion
  Future<bool> _validatePersonalInfo() async {


    print('\x1b[32m'"lib/user/registration_new.dart:  _validatePersonalInfo: isVoterIdAlreadyUsed() Executed!"'\x1b[0m');



    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = "Name is required");
      return false;
    }
    if (!RegExp(r'^\d{12}$').hasMatch(_aadhaarController.text)) {
      setState(() => _errorMessage = "Aadhaar must be exactly 12 digits");
      return false;
    }
    if (!RegExp(r'^[A-Z]{3}\d{7}$').hasMatch(_voterIdController.text)) {
      setState(
          () => _errorMessage = "Invalid Voter ID format (e.g., ABC1234567)");
      return false;
    }
    if (_selectedDate == null) {
      setState(() => _errorMessage = "Date of Birth is required");
      return false;
    }

    DateTime today = DateTime.now();
    DateTime adultDate = DateTime(today.year - 18, today.month, today.day);
    if (_selectedDate!.isAfter(adultDate)) {
      setState(() => _errorMessage = "You must be at least 18 years old");
      return false;
    }

    await voterIdCheck();
    await aadhaarCheck();


    if(isVoterIdAlreadyUsed){

      setState(() => _errorMessage = "Voter id is already used by someone!");
      return false;

    }

    if(isAadhaarAlreadyUsed){

      setState(() => _errorMessage = "Aadhaar is already used by someone!");
      return false;

    }


    setState(() => _errorMessage = null);
    return true;
  }

//funtion
  Future<bool> _validateContactInfo() async{

        print('\x1b[32m'"lib/user/registration_new.dart:  _validateContactInfo() Executed!"'\x1b[0m');


    if (!RegExp(r'^\d{10}$').hasMatch(_phoneController.text)) {
      setState(() => _errorMessage = "Phone number must be exactly 10 digits");
      return false;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(_emailController.text)) {
      setState(() => _errorMessage = "Enter a valid email address");
      return false;
    }
    if (_addressController.text.trim().length < 10) {
      setState(() => _errorMessage = "Please enter a complete address");
      return false;
    }
if (_selectedState == null) {
  setState(() => _errorMessage = "State is required");
  return false;
}

      await emailCheck();


    if(isEmailAlreadyUsed){

      setState(() => _errorMessage = "Email ID is already used by someone!");
      return false;

    }


    setState(() => _errorMessage = null);
    return true;
  }

//funtion
  bool _validateSecurity() {
    if (_passwordController.text.length < 8) {
      setState(() => _errorMessage = "Password must be at least 8 characters");
      return false;
    }

    bool hasUppercase = _passwordController.text.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = _passwordController.text.contains(RegExp(r'[a-z]'));
    bool hasDigit = _passwordController.text.contains(RegExp(r'[0-9]'));
    bool hasSpecialChar =
        _passwordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    if (!hasUppercase || !hasLowercase || !hasDigit || !hasSpecialChar) {
      setState(() => _errorMessage =
          "Password must contain uppercase, lowercase, digit and special character");
      return false;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = "Passwords do not match");
      return false;
    }

    if (!_acceptTerms) {
      setState(
          () => _errorMessage = "You must agree to the terms and conditions");
      return false;
    }

    setState(() => _errorMessage = null);
    return true;
  }


//funtion-new
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


print('\x1B[36m'"lib/user/registration.dart: _register(): debug: name: ${_dateOfBirthController.text}"'\x1B[0m');



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
            "state": _selectedState!,
            "district": _selectedDistrict!,
            "constituency": _selectedConstituency!,
          },
        ),
      ),
    );
  }

//funtion
  String _shortenWalletAddress(String address) {
    if (address.length > 12) {
      return address.substring(0, 6) +
          '...' +
          address.substring(address.length - 4);
    }
    return address;
  }

//funtion
  Future<void> _nextStep() async {
    bool isValid = false;
    switch (_currentStep) {
      case 0:
        isValid = await _validatePersonalInfo();
        break;
      case 1:
        isValid = await _validateContactInfo();
        break;
      default:
        isValid = false;
    }

    if (isValid) {
      setState(() {
        _currentStep += 1;
        _errorMessage = null;
      });
      _animController.reset();
      _animController.forward();
    }
  }

//funtion
  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep -= 1;
        _errorMessage = null;
      });
      _animController.reset();
      _animController.forward();
    }
  }

//widget
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime(DateTime.now().year - 18, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: textColor,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _dateOfBirthController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
      });
    }
  }

//widget
  void _showRegistrationSuccessDialog(String aadhaarNumber) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: primaryColor, size: 30),
            SizedBox(width: 10),
            Text(
              'Registration Successful',
              style: TextStyle(fontWeight: FontWeight.w600, color: primaryColor)
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your account has been created successfully with blockchain security.',
              style: TextStyle(),
            ),
            SizedBox(height: 20),
            Text(
              'Your Aadhaar ID:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.credit_card, color: primaryColor, size: 20),
                  SizedBox(width: 10),
                  Text(aadhaarNumber,
                      style: TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            if (_isWalletConnected && _walletAddress != null) ...[
              SizedBox(height: 16),
              Text(
                'Connected Wallet:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.account_balance_wallet,
                        color: Colors.blue.shade700, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _shortenWalletAddress(_walletAddress!),
                        style: TextStyle(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: Text('Go to Login',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

//widget
  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(
        _totalSteps,
        (index) => Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 4),
            height: 5,
            decoration: BoxDecoration(
              color:
                  index <= _currentStep ? primaryColor : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
      ),
    );
  }

//widget
  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Personal Information';
      case 1:
        return 'Contact Details';
      case 2:
        return 'Security Setup';
      default:
        return '';
    }
  }

//widget
  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildPersonalInfoStep();
      case 1:
        return _buildContactDetailsStep();
      case 2:
        return _buildSecurityStep();
      default:
        return Container();
    }
  }

//widget
  Widget _buildPersonalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(
          controller: _nameController,
          maxLength: 30,
          label: 'Name as per Voter ID',
          icon: Icons.person,
          Validator: Validators.validateName,
        ),
        SizedBox(height: 20),
        _buildTextField(
          controller: _aadhaarController,
          label: 'Aadhaar Number',
          icon: Icons.credit_card,
          keyboardType: TextInputType.number,
          maxLength: 12,
          Validator: Validators.validateAadhaar,
        ),
        SizedBox(height: 20),
        _buildTextField(
          controller: _voterIdController,
          maxLength: 10,
          label: 'Voter ID Number',
          icon: Icons.how_to_vote,
          textCapitalization: TextCapitalization.characters,
          Validator: Validators.validateVoterID,
        ),
        SizedBox(height: 20),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: AbsorbPointer(
            child: _buildTextField(
              readOnly: true, // user can't type manually
              controller: _dateOfBirthController,
              Validator: Validators.dateOfBirthValidator,
              label: 'Date of Birth',
              icon: Icons.calendar_today,
              suffixIcon: Icons.arrow_drop_down,
            ),
          ),
        ),
        SizedBox(height: 10),
        _buildInfoBox(
          text: 'You must be at least 18 years old to register as a voter.',
          icon: Icons.info_outline,
          backgroundColor: Colors.blue.shade50,
          textColor: Colors.blue.shade900,
          iconColor: Colors.blue.shade700,
        ),
      ],
    );
  }

//widget
  Widget _buildContactDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(
          controller: _phoneController,
          Validator: Validators.validatePhone,
          label: 'Phone Number',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          prefixText: '+91 ',
        ),
        SizedBox(height: 20),

        _buildTextField(
          controller: _emailController,
          Validator: Validators.validateEmail,
          label: 'Email Address',
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: 20),

        _buildTextField(
          controller: _addressController,
          Validator: Validators.addressValidator,
          label: 'Residential Address',
          icon: Icons.home,
          maxLines: 3,
          maxLength: 100,
          alignLabelWithHint: true,
        ),
        SizedBox(height: 20),

        DropdownButtonFormField<String>(
          isExpanded: true, // ✅ IMPORTANT FIX
          initialValue: _selectedState,
          decoration: InputDecoration(
            labelText: 'State',
            labelStyle: TextStyle(color: lightTextColor),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: errorColor),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: errorColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          items: _states.map((c) {
                          return DropdownMenuItem(value: c, child: Text(c,overflow: TextOverflow.ellipsis,));
                        }).toList(),
                        onChanged: (value) {
                          setState(() {

                            _selectedState = value;

                            // 🔴 reset dependent fields
                            _selectedDistrict = null;
                            _selectedConstituency = null;
                          });
                        },
        ),
        const SizedBox(height: 16),

        DropdownButtonFormField<String>(
          isExpanded: true, // ✅ IMPORTANT FIX
          initialValue: _selectedDistrict,
          decoration: InputDecoration(
            labelText: 'District',
            labelStyle: TextStyle(color: lightTextColor),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: errorColor),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: errorColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          items: (locationData[_selectedState] ?? {})
                          .keys
                          .map((district) {
                        return DropdownMenuItem(
                          value: district,
                          child: Text(district, overflow: TextOverflow.ellipsis),
                        );
                        }).toList(),
                        onChanged: (_selectedState == null ||
                            (locationData[_selectedState!] ?? {}).isEmpty)
                          ? null // 🔴 disables dropdown
                          : (value) {
                              setState(() {
                                _selectedDistrict = value;
                                _selectedConstituency = null;
                            });
                        },
        ),
        const SizedBox(height: 16),

        DropdownButtonFormField<String>(
          isExpanded: true, // ✅ IMPORTANT FIX
          initialValue: _selectedConstituency,
          validator: (value) => Validators.validateConstituency(value),
          decoration: InputDecoration(
            labelText: 'Constituency',
            labelStyle: TextStyle(color: lightTextColor),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: errorColor),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: errorColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
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


        _buildInfoBox(
          text:
              'Your phone number will be used for OTP verification during login.',
          icon: Icons.info_outline,
          backgroundColor: Colors.blue.shade50,
          textColor: Colors.blue.shade900,
          iconColor: Colors.blue.shade700,
        ),
      ],
    );
  }

//widget
  Widget _buildSecurityStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Blockchain wallet connection
        Container(
          padding: EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance_wallet,
                      color: Colors.blue.shade700, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Blockchain Wallet (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text(
                'Connect your blockchain wallet for enhanced security and alternative login options.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue.shade900,
                ),
              ),
              SizedBox(height: 15),
              if (_isWalletConnected && _walletAddress != null) ...[
                // Wallet connected UI
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: Colors.blue.shade700, size: 20),
                      SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Wallet Connected',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _shortenWalletAddress(_walletAddress!),
                            style: TextStyle(
                                fontSize: 13, color: textColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),

                TextButton.icon(
                  onPressed: _isWalletConnecting
                      ? null
                      : () async {
                          try {
                            await _blockchainService.disconnectWallet();
                            setState(() {
                              _isWalletConnected = false;
                              _walletAddress = null;
                            });
                          } catch (e) {
                            print("Error disconnecting wallet: $e");
                          }
                        },
                  icon: Icon(Icons.link_off,
                      size: 18, color: Colors.red.shade700),
                  label: Text(
                    'Disconnect Wallet',
                    style: TextStyle(
                        color: Colors.red.shade700, fontSize: 14),
                  ),
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: _isWalletConnecting ? null : _connectWallet,
                  icon: Icon(Icons.account_balance_wallet),
                  label: Text(
                    _isWalletConnecting ? 'Connecting...' : 'Connect Wallet',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: 20),

        // Password
        _buildPasswordField(
          controller: _passwordController,
          Validator: Validators.validatePassword,
          label: 'Password',
          icon: Icons.lock,
          obscureText: _obscurePassword,
          toggleObscure: () =>
              setState(() => _obscurePassword = !_obscurePassword),
        ),
        SizedBox(height: 10),

        // Password requirements
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Password must contain:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              SizedBox(height: 5),
              _buildPasswordRequirement(
                'At least 8 characters',
                _passwordController.text.length >= 8,
              ),
              _buildPasswordRequirement(
                'At least one uppercase letter (A-Z)',
                _passwordController.text.contains(RegExp(r'[A-Z]')),
              ),
              _buildPasswordRequirement(
                'At least one lowercase letter (a-z)',
                _passwordController.text.contains(RegExp(r'[a-z]')),
              ),
              _buildPasswordRequirement(
                'At least one number (0-9)',
                _passwordController.text.contains(RegExp(r'[0-9]')),
              ),
              _buildPasswordRequirement(
                'At least one special character /\n(!@#\$%^&*...)',
                _passwordController.text
                    .contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
              ),
            ],
          ),
        ),
        SizedBox(height: 20),

        // Confirm Password
        _buildPasswordField(
          controller: _confirmPasswordController,
          Validator: (value) => Validators.validateConfirmPassword(
            value,
            _passwordController.text,
          ),
          label: 'Confirm Password',
          icon: Icons.lock_outline,
          obscureText: _obscureConfirmPassword,
          toggleObscure: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword),
        ),
        SizedBox(height: 20),

        // Terms and conditions
        Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _acceptTerms,
                onChanged: (value) =>
                    setState(() => _acceptTerms = value ?? false),
                activeColor: primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 14, color: textColor),
                  children: [
                    TextSpan(text: 'I agree to the '),
                    TextSpan(
                      text: 'Terms of Service',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()..onTap = () {},
                    ),
                    TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()..onTap = () {},
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 15),

        // Security note
        _buildInfoBox(
          text:
              'Your password is securely hashed and stored using blockchain technology for enhanced security.',
          icon: Icons.security,
          backgroundColor: Color(0xFFF1F9F1),
          textColor: textColor,
          iconColor: primaryColor,
          borderColor: primaryColor.withOpacity(0.3),
        ),
      ],
    );
  }

//widget
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    int maxLines = 1,
    bool alignLabelWithHint = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? prefixText,
    IconData? suffixIcon,
    bool? readOnly,
    String? Function(String?)? Validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: Validator,
      maxLength: maxLength,
      maxLines: maxLines,
      readOnly: readOnly == true ? true : false,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: lightTextColor),
        prefixIcon: maxLines > 1
            ? Padding(
                padding: EdgeInsets.only(bottom: 50),
                child: Icon(icon, color: primaryColor))
            : Icon(icon, color: primaryColor),
        prefixText: prefixText,
        prefixStyle: prefixText != null
            ? TextStyle(
                fontSize: 15,
                color: textColor,
                fontWeight: FontWeight.w500,
              )
            : null,
        suffixIcon:
            suffixIcon != null ? Icon(suffixIcon, color: primaryColor) : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        counterText: maxLength != null ? "" : null,
        alignLabelWithHint: alignLabelWithHint,
      ),
      style: TextStyle(fontSize: 15, color: textColor),
    );
  }

//widget
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool obscureText,
    required VoidCallback toggleObscure,
    String? Function(String?)? Validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: Validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: lightTextColor),
        prefixIcon: Icon(icon, color: primaryColor),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: lightTextColor,
          ),
          onPressed: toggleObscure,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      style: TextStyle(fontSize: 15, color: textColor),
    );
  }

//widget
  Widget _buildPasswordRequirement(String requirement, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.circle_outlined,
          size: 14,
          color: isMet ? Colors.green : Colors.grey,
        ),
        SizedBox(width: 8),
        Text(
          requirement,
          style: TextStyle(
            fontSize: 12,
            color: isMet ? Colors.green.shade700 : Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

//widget
  Widget _buildInfoBox({
    required String text,
    required IconData icon,
    required Color backgroundColor,
    required Color textColor,
    required Color iconColor,
    Color? borderColor,
  }) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: borderColor != null ? Border.all(color: borderColor) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 13, color: textColor)),
          ),
        ],
      ),
    );
  }

//widget
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [backgroundColor, Color(0xFFD4EBD7)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Bar
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: primaryColor),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Step indicator
                  _buildStepIndicator(),
                  SizedBox(height: 10),

                  // Step title
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${_currentStep + 1}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        _getStepTitle(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Form container
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: AnimatedBuilder(
                        animation: _fadeAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _fadeAnimation.value,
                            child: _buildCurrentStep(),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Error message
                  if (_errorMessage != null) ...[
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: errorColor, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: errorColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                  ],

                  // Navigation buttons
                  Row(
                    children: [
                      if (_currentStep > 0)
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: primaryColor,
                              side: BorderSide(color: primaryColor),
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _prevStep,
                            child: Text(
                              'Previous',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      if (_currentStep > 0) SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          onPressed: _isLoading
                              ? null
                              : (_currentStep < _totalSteps - 1)
                                  ? _nextStep
                                  : _register,
                          child: _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                    strokeWidth: 3,
                                  ),
                                )
                              : Text(
                                  _currentStep < _totalSteps - 1
                                      ? 'Next'
                                      : 'Register',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
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
      ),
    );
  }


  void debug() {
    debugPrint('\x1B[34m'
        'lib/Registration.dart: executed'
        '\x1B[0m');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aadhaarController.dispose();
    _voterIdController.dispose();
    _dateOfBirthController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _stateController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animController.dispose();
    super.dispose();
  }

}
