import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../services/auth_service.dart';
import 'login_new.dart';
import '../services/firestore_service.dart';
import 'package:intl/intl.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authService = AuthService();
  bool _isEditing = false;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _dateOfBirthController;
  late TextEditingController _voterIdController;
  late TextEditingController _aadhaarController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  final Color primaryColor = Color(0xFF1E8449);
  final Color textColor = Color(0xFF2C3E50);


  String? _selectedState;
  String? _selectedDistrict;
  String? _selectedConstituency;
  DateTime? _selectedDate;



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

List<String> get districts => (locationData[_selectedState] ?? {}).keys.toList();



  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController();
    _dateOfBirthController = TextEditingController();
    _voterIdController = TextEditingController();
    _aadhaarController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    // _authService.debugCurrentUser();

    _loadUserData(); // 👈 separate function
  }


final _firestoreService = FirestoreService();


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

    print('\x1B[35m'"lib/user/profile.dart: _selectDate(): debug: pickedDate: ${pickedDate}"'\x1B[0m]');


    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _dateOfBirthController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
      });
    }

    print('\x1B[35m'"lib/user/profile.dart: _selectDate(): debug: _dateOfBirthController: ${_dateOfBirthController.text}"'\x1B[0m]');

  }


  void _loadUserData() {
  final user = _authService.currentUser;

  if (user != null) {
    _nameController.text = user.name;
    _dateOfBirthController.text = user.dateOfBirth;
    _voterIdController.text = user.voterId;
    _aadhaarController.text = user.aadhaar;
    _emailController.text = user.email;
    _phoneController.text = user.phone;
    _addressController.text = user.address;
    _selectedState = user.state;
    _selectedDistrict = user.district;
    _selectedConstituency = user.constituency;
  }
}

  Future<void> _saveProfile() async {
    debugPrint('\x1B[32m'
        'lib/user/profile.dart: _saveProfile() executed'
        '\x1B[0m');

        // print('\x1b[36m'"Profile: Date of Birth: ${_dateOfBirthController.text}"'\x1b[0m');
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);






    try {
      final success = await _authService.updateProfile(
        name: _nameController.text.trim(),
        dateOfBirth: _dateOfBirthController.text.trim(),
        voterId: _voterIdController.text.trim(),
        aadhaar: _aadhaarController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        state: _selectedState ?? '',
        district: _selectedDistrict ?? '',
        constituency: _selectedConstituency ?? '',
      );



      if (!mounted) return;

      if (success) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile'),
            backgroundColor: AppColors.error,
          ),
        );
      }

      print(
          '\x1B[32m' 'lib/user/profile.dart: `_saveProfile` sucsses' '\x1B[0m');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
      print('\x1B[31m' 'lib/user/profile.dart: `_saveProfile` fail' '\x1B[0m');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _logout() async {
    debugPrint('\x1B[32m'
        'lib/user/profile.dart: _logout() executed'
        '\x1B[0m');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginPageNew()),
        (route) => false,
      );
    }
    print('\x1B[32m' 'lib/user/profile.dart: `_logout` sucsses' '\x1B[0m');
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.paddingMedium),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: AppColors.primary,
                child: Text(
                  user?.name.isNotEmpty == true
                      ? user!.name[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    fontSize: 48,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.verified,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user?.name ?? 'Voter',
            style: AppTextStyles.heading2,
          ),
          Text(
            user?.email ?? '',
            style: AppTextStyles.body2,
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimens.borderRadiusLarge),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Text(
                          'Personal Information',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        if (!_isEditing)
                          TextButton.icon(
                            onPressed: () => setState(() => _isEditing = true),
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edit'),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  _buildProfileField(
                    icon: Icons.person_outlined,
                    label: 'Full Name',
                    child: _isEditing
                        ? TextFormField(
                            maxLength: 30,
                            controller: _nameController,
                            validator: Validators.validateName,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          )
                        : Text(user?.name ?? '-'),
                  ),



                  _buildProfileField(
                    icon: Icons.calendar_today_outlined,
                    label: 'Date of Birth',
                    child: _isEditing
                        ? TextFormField(
                            controller: _dateOfBirthController, // ✅ correct controller
                            readOnly: true, // ✅ important
                            // validator: Validators.dateOfBirthValidator,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              hintText: 'Select DOB',
                            ),
                            onTap: () => _selectDate(context),

                            // () async {
                            //   DateTime? pickedDate = await showDatePicker(
                            //     context: context,
                            //     initialDate: DateTime(2000),
                            //     firstDate: DateTime(1900),
                            //     lastDate: DateTime.now(),
                            //   );

                            //   if (pickedDate != null) {
                            //     setState(() {
                            //       // _dateOfBirthController.text =
                            //           // "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                            //       _dateOfBirthController.text = DateFormat('dd/MM/yyyy').format(pickedDate);

                            //     });
                            //   }
                            // },
                          )
                        : Text(user?.dateOfBirth ?? '-'),
                  ),


                  _buildProfileField(
                      icon: Icons.credit_card_outlined,
                      label: 'Voter ID Status',
                      child: 
                      Row(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.lock,
                                        size: 14,
                                        color: AppColors.success), // 👈 ADD
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.check_circle,
                                      size: 14,
                                      color: AppColors.success,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Verified',
                                      style: TextStyle(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Expanded(
                            child:_isEditing
                              ? TextFormField(
                                  controller: _voterIdController,
                                  maxLength: 10,
                                  validator: Validators.validateVoterID,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                )
                              : Text(user?.voterId ?? '-'),
                          ),
                        ]
                      )
                    ),

                  _buildProfileField(
                      icon: Icons.credit_card_outlined,
                      label: 'Aadhaar Status',
                      child: 
                      Row(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.lock,
                                        size: 14,
                                        color: AppColors.success), // 👈 ADD
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.check_circle,
                                      size: 14,
                                      color: AppColors.success,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Verified',
                                      style: TextStyle(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Expanded(
                            child:
                            _isEditing
                              ? TextFormField(
                                  controller: _aadhaarController,
                                  maxLength: 12,
                                  keyboardType: TextInputType.number,
                                  validator: Validators.validateAadhaar,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                )
                              : Text(user?.aadhaar ?? '-'),
                          ),
                        ]
                      )
                    ),


                  


                  _buildProfileField(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    child: _isEditing
                        ? TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: Validators.validateEmail,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          )
                        : Text(user?.email ?? '-'),
                  ),

                  _buildProfileField(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    child: _isEditing
                        ? TextFormField(
                            controller: _phoneController,
                            validator: Validators.validatePhone,
                            maxLength: 10,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          )
                        : Text(user?.phone ?? '-'),
                  ),


                  _buildProfileField(
                    icon: Icons.person_outlined,
                    label: 'Address',
                    child: _isEditing
                        ? TextFormField(
                            controller: _addressController,
                            validator: Validators.validateName,
                            maxLength: 100,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          )
                        : Text(user?.address ?? '-'),
                  ),


                  _buildProfileField(
                    icon: Icons.location_on_outlined,
                    label: 'State',
                    
                    child: _isEditing
                        ? DropdownButtonFormField<String>(
                                    isExpanded: true, // ✅ IMPORTANT FIX

                            value: _states.contains(_selectedState) ? _selectedState : null,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
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
                          )
                        : Text(user?.state ?? '-'),
                  ),


                  _buildProfileField(
                    icon: Icons.location_on_outlined,
                    label: 'District',
                    child: _isEditing
                        ? DropdownButtonFormField<String>(
                                    isExpanded: true, // ✅ IMPORTANT FIX

                            value: districts.contains(_selectedDistrict)
                                ? _selectedDistrict
                                : null,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
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
                          )
                        : Text(user?.district ?? '-'),
                  ),


                  _buildProfileField(
                    icon: Icons.location_on_outlined,
                    label: 'Constituency',
                    child: _isEditing
                        ? DropdownButtonFormField<String>(
                                    isExpanded: true, // ✅ IMPORTANT FIX

                            value: _constituencies.contains(_selectedConstituency)
                                      ? _selectedConstituency
                                      : null,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            items: _constituencies.map((c) {
                              return DropdownMenuItem(value: c, child: Text(c));
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedConstituency = value);
                            },
                          )
                        : Text(user?.constituency ?? '-'),
                  ),




                  if (_isEditing)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() => _isEditing = false);
                                _nameController.text = user?.name ?? '';
                                _phoneController.text = user?.phone ?? '';
                                _selectedConstituency = user?.constituency;
                              },
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Save'),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimens.borderRadiusLarge),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildMenuItem(
                  icon: Icons.info_outlined,
                  title: 'Voting Guidelines',
                  onTap: () => _showGuidelines(),
                ),
                const Divider(height: 1),

                _buildMenuItem(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {},
                ),
                const Divider(height: 1),

                _buildMenuItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () {},
                ),
                const Divider(height: 1),

                _buildMenuItem(
                  icon: Icons.info_outlined,
                  title: 'Host Credentials',
                  onTap: () => _showHostCredentials(),
                ),
                const Divider(height: 1),
  

                _buildMenuItem(
                  icon: Icons.logout,
                  title: 'Logout',
                  color: AppColors.error,
                  onTap: _logout,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'E-Vote v1.0.0',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProfileField({
    required IconData icon,
    required String label,
    required Widget child,
    bool showBorder = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: showBorder
            ? const Border(
                bottom: BorderSide(color: AppColors.divider, width: 0.5))
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption),
                const SizedBox(height: 4),
                DefaultTextStyle(
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                  child: child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.textSecondary),
      title: Text(
        title,
        style: TextStyle(color: color ?? AppColors.textPrimary),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: color ?? AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }

  void _showGuidelines() {
    debugPrint('\x1B[32m'
        'lib/user/profile.dart: _showGuidelines() executed'
        '\x1B[0m');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Voting Guidelines',
                style: AppTextStyles.heading2,
              ),
              const SizedBox(height: 24),

              _buildGuideline(
                '1',
                'Verify Your Identity',
                'Ensure your Aadhaar and phone are verified before voting.',
              ),
              _buildGuideline(
                '2',
                'One Vote Per Election',
                'You can only vote once in each election. Choose wisely.',
              ),
              _buildGuideline(
                '3',
                'Blockchain Security',
                'Your vote is securely stored on the blockchain and cannot be altered.',
              ),
              _buildGuideline(
                '4',
                'Save Transaction Hash',
                'Keep your transaction hash for future verification.',
              ),
              _buildGuideline(
                '5',
                'Report Issues',
                'Contact support if you face any issues during voting.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHostCredentials() {
    debugPrint('\x1B[32m'
        'lib/user/profile.dart: _showHostCredentials() executed'
        '\x1B[0m');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => StreamBuilder<Map<String, dynamic>>(
          stream: _firestoreService.getHostCredentialsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            final data = snapshot.data ?? {};
            final rpcUrl = "http://${data['hostIp']}:7545";
            final privateKey = data['privateKey'] ?? 'N/A';
            final contractAddress = data['contractAddress'] ?? 'N/A';

            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Host Credentials',
                    style: AppTextStyles.heading2,
                  ),
                  const SizedBox(height: 24),

                  _buildGuideline(
                    '1',
                    'RPC Endpoint',
                    rpcUrl,
                  ),
                  _buildGuideline(
                    '2',
                    'PRIVATE KEY',
                    privateKey,
                  ),
                  _buildGuideline(
                    '3',
                    'CONTRACT ADDRESS',
                    contractAddress,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }


  Widget _buildGuideline(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(description, style: AppTextStyles.body2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void debug() {
    debugPrint('\x1B[34m'
        'lib/user/profile.dart: executed'
        '\x1B[0m');
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

    super.dispose();
    print('\x1B[32m'
        'lib/user/profile.dart: `dispose` sucsses'
        '\x1B[0m');
  }
}
