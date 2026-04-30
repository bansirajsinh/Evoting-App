import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/blockchain_service.dart';
import '../user/login.dart';
import 'manage_elections.dart';
import 'manage_candidates.dart';
import 'manage_voters.dart';
import 'manage_parties.dart';
import 'results.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _blockchainService = BlockchainService();

  bool _blockchainConnected = false;

  @override
  void initState() {
    super.initState();
    _connectBlockchain();
    debug();
  }

  Future<void> _connectBlockchain() async {
    debugPrint('\x1B[32m'
    'lib/admin/dashboard.dart: _connectBlockchain() executed'
    '\x1B[0m');
    try {
      final connected = await _blockchainService.connect();
      setState(() => _blockchainConnected = connected);
    } catch (e) {
      debugPrint('Blockchain connection error: $e');
    }
  }

  void _logout() async {
    debugPrint('\x1B[32m'
    'lib/admin/dashboard.dart: _logout() executed'
    '\x1B[0m');
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout from admin panel?'),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppDimens.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppDimens.borderRadiusLarge),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white24,
                      child: Icon(
                        Icons.admin_panel_settings,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, Admin',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                          const Text(
                            'System Administrator',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Overview',
                style: AppTextStyles.heading3,
              ),
              
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: StreamBuilder<int>(
                      stream: _firestoreService.streamTotalElections(),
                      builder: (context, snapshot) {

                        if (snapshot.hasError) {
                          return _buildStatCard(
                            'Total Elections',
                            'Error',
                            Icons.error,
                            Colors.red,
                          );
                        }

                        if (!snapshot.hasData) {
                          return _buildStatCard(
                            'Total Elections',
                            '...',
                            Icons.how_to_vote,
                            AppColors.primary,
                          );
                        }

                        return _buildStatCard(
                          'Total Elections',
                          '${snapshot.data}',
                          Icons.how_to_vote,
                          AppColors.primary,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StreamBuilder<int>(
                      stream: _firestoreService.streamActiveElections(),
                      builder: (context, snapshot) {

                        if (snapshot.hasError) {
                          return _buildStatCard(
                            'Active Now',
                            'Error',
                            Icons.error,
                            Colors.red,
                          );
                        }

                        if (!snapshot.hasData) {
                          return _buildStatCard(
                            'Active Now',
                            '...',
                            Icons.play_circle,
                            AppColors.success,
                          );
                        }

                        return _buildStatCard(
                          'Active Now',
                          '${snapshot.data}',
                          Icons.play_circle,
                          AppColors.success,
                        );
                      },
                      
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StreamBuilder<int>(
                      stream: _firestoreService.streamTotalVoters(),
                      builder: (context, snapshot) {

                        if (snapshot.hasError) {
                          return _buildStatCard(
                            'Registered Voters',
                            'Error',
                            Icons.error,
                            Colors.red,
                          );
                        }

                        if (!snapshot.hasData) {
                          return _buildStatCard(
                            'Registered Voters',
                            '...',
                            Icons.people,
                            AppColors.warning,
                          );
                        }

                        return _buildStatCard(
                          'Registered Voters',
                          '${snapshot.data}',
                          Icons.people,
                          AppColors.warning,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StreamBuilder<int>(
                      stream: _firestoreService.streamTotalVotes(),
                      builder: (context, snapshot) {

                        if (snapshot.hasError) {
                          return _buildStatCard(
                            'Total Votes',
                            'Error',
                            Icons.error,
                            Colors.red,
                          );
                        }

                        if (!snapshot.hasData) {
                          return _buildStatCard(
                            'Total Votes',
                            '...',
                            Icons.ballot,
                            Colors.purple,
                          );
                        }

                        return _buildStatCard(
                          'Total Votes',
                          '${snapshot.data}',
                          Icons.ballot,
                          Colors.purple,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                'Management',
                style: AppTextStyles.heading3,
              ),
              const SizedBox(height: 16),
              _buildMenuCard(
                icon: Icons.how_to_vote,
                title: 'Manage Elections',
                subtitle: 'Create and schedule elections',
                color: AppColors.primary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManageElectionsPage()),
                ),
              ),
              _buildMenuCard(
                icon: Icons.flag,
                title: 'Manage Parties',
                subtitle: 'Register political parties and symbols',
                color: Colors.teal,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManagePartiesPage()),
                ),
              ),
              _buildMenuCard(
                icon: Icons.person_pin,
                title: 'Manage Candidates',
                subtitle: 'Add and verify candidates',
                color: Colors.orange,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManageCandidatesPage()),
                ),
              ),
              _buildMenuCard(
                icon: Icons.people,
                title: 'Manage Voters',
                subtitle: 'Verify voter eligibility',
                color: Colors.blue,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManageVotersPage()),
                ),
              ),
              _buildMenuCard(
                icon: Icons.bar_chart,
                title: 'View Results',
                subtitle: 'Election analytics and results',
                color: Colors.purple,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ResultsPage()),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'System Status',
                style: AppTextStyles.heading3,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimens.borderRadius),
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
                    _buildStatusRow(
                      'Firebase',
                      'Connected',
                      AppColors.success,
                    ),
                    const Divider(),
                    _buildStatusRow(
                      'Blockchain (Ganache)',
                      _blockchainConnected ? 'Connected' : 'Disconnected',
                      _blockchainConnected ? AppColors.success : AppColors.error,
                    ),
                    const Divider(),
                    _buildStatusRow(
                      'System Health',
                      'Operational',
                      AppColors.success,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimens.borderRadius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(subtitle, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void debug() {
    debugPrint('\x1B[34m'
        'lib/admin/dashboard.dart: executed'
        '\x1B[0m');
  }
}
