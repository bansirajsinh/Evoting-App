import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/firestore_service.dart';
import '../models/voter_profile.dart';

class ManageVotersPage extends StatefulWidget {
  const ManageVotersPage({super.key});

  @override
  State<ManageVotersPage> createState() => _ManageVotersPageState();
}

class _ManageVotersPageState extends State<ManageVotersPage> {
  final _firestoreService = FirestoreService();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    debug();
  }

  Future<void> _toggleEligibility(VoterProfile voter) async {
    debugPrint('\x1B[32m'
    'lib/admin/manage_voters.dart: _toggleEligibility() executed'
    '\x1B[0m');
    await _firestoreService.updateVoterEligibility(
      voter.id,
      !voter.isEligible,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          voter.isEligible
              ? 'Voter marked as ineligible'
              : 'Voter marked as eligible',
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showVoterDetails(VoterProfile voter) {
    debugPrint('\x1B[32m'
    'lib/admin/manage_voters.dart: _showVoterDetails() executed'
    '\x1B[0m');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    voter.name.isNotEmpty
                        ? voter.name[0].toUpperCase()
                        : 'V',
                    style: const TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(voter.name, style: AppTextStyles.heading2),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: voter.isEligible
                              ? AppColors.success.withOpacity(0.1)
                              : AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          voter.isEligible
                              ? 'ELIGIBLE'
                              : 'INELIGIBLE',
                          style: TextStyle(
                            color: voter.isEligible
                                ? AppColors.success
                                : AppColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            _buildDetailRow(Icons.email_outlined, 'Email', voter.email),
            _buildDetailRow(Icons.phone_outlined, 'Phone', voter.phone),
            _buildDetailRow(Icons.location_on_outlined, 'Constituency',
                voter.constituency),
            _buildDetailRow(
              Icons.calendar_today_outlined,
              'Registered',
              _formatDate(voter.registeredAt),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _toggleEligibility(voter);
                    },
                    icon: Icon(
                      voter.isEligible
                          ? Icons.block
                          : Icons.check_circle,
                      color: voter.isEligible
                          ? AppColors.error
                          : AppColors.success,
                    ),
                    label: Text(
                      voter.isEligible
                          ? 'Mark Ineligible'
                          : 'Mark Eligible',
                      style: TextStyle(
                        color: voter.isEligible
                            ? AppColors.error
                            : AppColors.success,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              const SizedBox(height: 2),
              Text(value, style: AppTextStyles.body1),
            ],
          ),
        ],
      ),
    );
  }

  // Widget _buildFilterChip(String label, int count) {
  //   return Container(
  //     padding:
  //     const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(20),
  //       border: Border.all(color: AppColors.divider),
  //     ),
  //     child: Text(
  //       '$label ($count)',
  //       style: const TextStyle(fontSize: 12),
  //     ),
  //   );
  // }

  Widget _buildVoterCard(VoterProfile voter) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(AppDimens.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius:
        BorderRadius.circular(AppDimens.borderRadius),
        onTap: () => _showVoterDetails(voter),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor:
                AppColors.primary.withOpacity(0.1),
                child: Text(
                  voter.name.isNotEmpty
                      ? voter.name[0].toUpperCase()
                      : 'V',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      voter.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(voter.email,
                        style: AppTextStyles.caption),
                    Text(voter.constituency,
                        style: AppTextStyles.caption),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: voter.isEligible
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.error.withOpacity(0.1),
                  borderRadius:
                  BorderRadius.circular(4),
                ),
                child: Text(
                  voter.isEligible
                      ? 'Eligible'
                      : 'Ineligible',
                  style: TextStyle(
                    color: voter.isEligible
                        ? AppColors.success
                        : AppColors.error,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Voters'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding:
            const EdgeInsets.all(AppDimens.paddingMedium),
            child: TextField(
              onChanged: (value) =>
                  setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search voters...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                      AppDimens.borderRadius),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<VoterProfile>>(
              stream:
              _firestoreService.getAllVotersStream(),
              builder: (context, snapshot) {

                // 🔴 1. Error state
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Something went wrong'),
                  );
                }

                // ⏳ 2. Loading state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final voters = snapshot.data!;

                final filtered = voters.where((voter) {
                  if (_searchQuery.isEmpty) return true;
                  return voter.name
                      .toLowerCase()
                      .contains(
                      _searchQuery.toLowerCase()) ||
                      voter.email
                          .toLowerCase()
                          .contains(
                          _searchQuery.toLowerCase()) ||
                      voter.phone
                          .contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.search_off, size: 60),
                        SizedBox(height: 10),
                        Text('No voters found'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(
                      AppDimens.paddingMedium),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _buildVoterCard(
                        filtered[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  void debug() {
    debugPrint('\x1B[34m'
        'lib/admin/manage_elections.dart: executed'
        '\x1B[0m');
  }
}
