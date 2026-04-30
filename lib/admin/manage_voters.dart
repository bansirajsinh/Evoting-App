import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/firestore_service.dart';
import '../models/app_user.dart';

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

  void _showVoterDetails(AppUser voter) {
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
                    voter.name.isNotEmpty ? voter.name[0].toUpperCase() : 'V',
                    style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(voter.name, style: AppTextStyles.heading2),
                      Text("Voter ID: ${voter.voterId}", style: AppTextStyles.body2),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            _buildDetailRow(Icons.info_outline, 'Verification Status', voter.verificationStatus ?? 'Pending'),
            _buildDetailRow(Icons.location_on_outlined, 'Ward', voter.ward),
            _buildDetailRow(Icons.credit_card_outlined, 'Voter Slip No.', voter.voterSlipNumber ?? 'Not Assigned'),
            _buildDetailRow(Icons.calendar_today_outlined, 'DOB', voter.dateOfBirth),
            _buildDetailRow(Icons.phone_outlined, 'Phone', voter.phone),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await _firestoreService.updateVoterVerification(voter.id, 'Verified', 'admin_uid');
                      if (mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                    child: const Text('Verify Voter'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await _firestoreService.updateVoterVerification(voter.id, 'Rejected', 'admin_uid');
                      if (mounted) Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                    child: const Text('Reject Verification'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              Text(value, style: AppTextStyles.body1),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Voters (District Roll)'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search by Name or Voter ID',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<AppUser>>(
              stream: _firestoreService.getAllVotersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('No voters in district roll.'));

                final voters = snapshot.data!.where((v) => 
                  v.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                  v.voterId.toLowerCase().contains(_searchQuery.toLowerCase())
                ).toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: voters.length,
                  itemBuilder: (context, index) {
                    final v = voters[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text(v.name[0])),
                        title: Text(v.name),
                        subtitle: Text('Ward: ${v.ward} | Status: ${v.verificationStatus ?? "Pending"}'),
                        trailing: Icon(
                          v.verificationStatus == 'Verified' ? Icons.verified : Icons.pending_actions,
                          color: v.verificationStatus == 'Verified' ? AppColors.success : AppColors.warning,
                        ),
                        onTap: () => _showVoterDetails(v),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void debug() => debugPrint('\x1B[34mManageVotersPage executed\x1B[0m');
}
