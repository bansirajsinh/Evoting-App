import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../services/auth_service.dart';
import 'login.dart';
import '../services/firestore_service.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authService = AuthService();
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _dateOfBirthController;
  late TextEditingController _voterIdController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _wardController;
  
  final Color primaryColor = const Color(0xFF1E8449);
  final Color textColor = const Color(0xFF2C3E50);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _dateOfBirthController = TextEditingController();
    _voterIdController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _wardController = TextEditingController();

    _loadUserData();
    debug();
  }

  void _loadUserData() {
    final user = _authService.currentUser;
    if (user != null) {
      _nameController.text = user.name;
      _dateOfBirthController.text = user.dateOfBirth;
      _voterIdController.text = user.voterId;
      _emailController.text = user.email;
      _phoneController.text = user.phone;
      _wardController.text = user.ward;
    }
  }

  void _logout() async {
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
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
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
                  user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                  style: const TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold),
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
                  child: const Icon(Icons.verified, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(user?.name ?? 'Voter', style: AppTextStyles.heading2),
          Text(user?.email ?? '', style: AppTextStyles.body2),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimens.borderRadiusLarge),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Personal Information (Read-Only)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const Divider(height: 1),
                _buildProfileField(icon: Icons.person_outlined, label: 'Full Name', value: user?.name ?? '-'),
                _buildProfileField(icon: Icons.calendar_today_outlined, label: 'Date of Birth', value: user?.dateOfBirth ?? '-'),
                _buildProfileField(icon: Icons.credit_card_outlined, label: 'Voter ID', value: user?.voterId ?? '-'),
                _buildProfileField(icon: Icons.email_outlined, label: 'Email', value: user?.email ?? '-'),
                _buildProfileField(icon: Icons.phone_outlined, label: 'Phone', value: user?.phone ?? '-'),
                _buildProfileField(icon: Icons.location_on_outlined, label: 'Ward', value: user?.ward ?? '-'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimens.borderRadiusLarge),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                _buildMenuItem(icon: Icons.info_outlined, title: 'Voting Guidelines', onTap: () => _showGuidelines()),
                const Divider(height: 1),
                _buildMenuItem(icon: Icons.help_outline, title: 'Help & Support', onTap: () {}),
                const Divider(height: 1),
                _buildMenuItem(icon: Icons.privacy_tip_outlined, title: 'Privacy Policy', onTap: () {}),
                const Divider(height: 1),
                _buildMenuItem(icon: Icons.logout, title: 'Logout', color: AppColors.error, onTap: _logout),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text('District E-Vote v2.0.0', style: AppTextStyles.caption),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProfileField({required IconData icon, required String label, required String value}) {
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.5))),
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
                Text(value, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary)),
              ],
            ),
          ),
          if (label == 'Voter ID')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
              child: const Row(
                children: [
                  Icon(Icons.verified, size: 14, color: AppColors.success),
                  SizedBox(width: 4),
                  Text('Verified', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 10)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({required IconData icon, required String title, required VoidCallback onTap, Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.textSecondary),
      title: Text(title, style: TextStyle(color: color ?? AppColors.textPrimary)),
      trailing: Icon(Icons.chevron_right, color: color ?? AppColors.textSecondary),
      onTap: onTap,
    );
  }

  void _showGuidelines() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('District Voting Guidelines', style: AppTextStyles.heading2),
              const SizedBox(height: 24),
              _buildGuideline('1', 'Single Ward Voting', 'You can only vote for candidates in your registered Ward.'),
              _buildGuideline('2', 'One Vote Per Election', 'You can only vote once. Choice is permanent.'),
              _buildGuideline('3', 'Blockchain Verified', 'Your vote is secured by decentralized blockchain technology.'),
              _buildGuideline('4', 'Secret Ballot', 'Your specific candidate choice is not stored with your identity.'),
            ],
          ),
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
          CircleAvatar(radius: 12, backgroundColor: AppColors.primary, child: Text(number, style: const TextStyle(color: Colors.white, fontSize: 12))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(description, style: AppTextStyles.body2),
            ]),
          ),
        ],
      ),
    );
  }

  void debug() => debugPrint('\x1B[34mProfilePage executed\x1B[0m');

  @override
  void dispose() {
    _nameController.dispose();
    _dateOfBirthController.dispose();
    _voterIdController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _wardController.dispose();
    super.dispose();
  }
}
