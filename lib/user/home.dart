import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/blockchain_service.dart';
import 'voting.dart';
import 'history.dart';
import 'profile.dart';
import 'login.dart';
import '../models/election.dart';
import 'user_results.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const HomePage({super.key, this.userData});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
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
    debugPrint('\x1B[32m''lib/user/home.dart: _connectBlockchain() executed''\x1B[0m');
    try {
      await _blockchainService.connect();
      setState(() => _blockchainConnected = true);
    } catch (e) {
      debugPrint('Blockchain connection failed: $e');
      setState(() => _blockchainConnected = false);
    }
  }

  void _logout() async {
    debugPrint('\x1B[32m''lib/user/home.dart: _logout() executed''\x1B[0m');
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_getTitle()),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.how_to_vote_outlined),
            activeIcon: Icon(Icons.how_to_vote),
            label: 'Vote',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Result',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0: return 'District Election Dashboard';
      case 1: return 'Cast Your Vote';
      case 2: return 'Election Results';
      case 3: return 'My Voting History';
      case 4: return 'My Profile';
      default: return 'E-Vote';
    }
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0: return _buildDashboard();
      case 1:
        return StreamBuilder<List<Election>>(
          stream: _firestoreService.getElectionsStream(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Center(child: Text('Error loading elections'));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final activeElections = snapshot.data!.where((e) => e.status == 'Polling' || e.status == 'active').toList();
            return VotingPage(elections: activeElections);
          },
        );
      case 2: return const UserResultsPage();
      case 3: return const HistoryPage();
      case 4: return const ProfilePage();
      default: return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    final user = _authService.currentUser;

    return StreamBuilder<List<Election>>(
      stream: _firestoreService.getElectionsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Error loading elections'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('No active district elections.'));

        final allElections = snapshot.data!;
        final activeElections = allElections.where((e) => e.status == 'Polling' || e.status == 'active').toList();
        final upcomingElections = allElections.where((e) => e.status == 'Notified' || e.status == 'Nomination Open' || e.status == 'upcoming').toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppDimens.borderRadiusLarge),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Text(
                            user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                            style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Voter Account', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                              Text(user?.name ?? 'Voter', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                              Text('Voter ID: ${user?.voterId ?? "N/A"}', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text('Ward: ${user?.ward ?? "N/A"}', style: const TextStyle(color: Colors.white, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (activeElections.isNotEmpty) ...[
                const Text('Active Elections', style: AppTextStyles.heading3),
                const SizedBox(height: 12),
                ...activeElections.map((e) => _buildElectionCard(e)),
              ],
              if (upcomingElections.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text('Upcoming Elections', style: AppTextStyles.heading3),
                const SizedBox(height: 12),
                ...upcomingElections.map((e) => _buildElectionCard(e)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildElectionCard(Election election) {
    bool isActive = election.status == 'Polling' || election.status == 'active';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.borderRadius),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimens.borderRadius),
          onTap: isActive ? () => setState(() => _currentIndex = 1) : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        election.status.toUpperCase(),
                        style: TextStyle(color: isActive ? AppColors.success : AppColors.warning, fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ),
                    const Spacer(),
                    Text('CODE: ${election.electionId}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(election.title, style: AppTextStyles.heading3),
                const SizedBox(height: 4),
                Text('District: ${election.district} | ${election.municipalityType}', style: AppTextStyles.caption),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        isActive ? 'Polling Day: ${_formatDate(election.pollingDate)}' : 'Notification: ${_formatDate(election.notificationDate ?? election.createdAt)}',
                        style: AppTextStyles.caption,
                      ),
                    ),
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                        child: const Text('Go to Ballot', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
  void debug() => debugPrint('\x1B[34m''lib/user/home.dart: executed''\x1B[0m');
}
