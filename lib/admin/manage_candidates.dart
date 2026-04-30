import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/firestore_service.dart';
import '../models/election.dart';
import '../models/candidate.dart';
import '../models/party.dart';

class ManageCandidatesPage extends StatefulWidget {
  const ManageCandidatesPage({super.key});

  @override
  State<ManageCandidatesPage> createState() => _ManageCandidatesPageState();
}

class _ManageCandidatesPageState extends State<ManageCandidatesPage> {
  final _firestoreService = FirestoreService();

  List<Election> _elections = [];
  Election? _selectedElection;
  List<Party> _parties = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    debug();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final elections = await _firestoreService.getElections();
      final parties = await _firestoreService.getParties();

      setState(() {
        _elections = elections;
        _parties = parties;

        if (elections.isNotEmpty) {
          _selectedElection = elections.first;
        }
      });
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddEditDialog([Candidate? candidate]) {
    debugPrint('\x1B[32m'
    'lib/admin/manage_candidates.dart: _showAddEditDialog() executed'
    '\x1B[0m');
    final isEditing = candidate != null;

    final nameController = TextEditingController(text: candidate?.candidateName ?? '');
    final wardController = TextEditingController(text: candidate?.ward ?? '');
    final phoneController = TextEditingController(text: candidate?.phone ?? '');
    final emailController = TextEditingController(text: candidate?.email ?? '');
    final aadharController = TextEditingController(text: candidate?.aadharNumber ?? '');
    final panController = TextEditingController(text: candidate?.panNumber ?? '');
    final assetController = TextEditingController(text: candidate?.assetValue ?? '');
    final criminalDetailsController = TextEditingController(text: candidate?.criminalDetails ?? '');
    final qualificationController = TextEditingController(text: candidate?.qualification ?? '');

    String? selectedPartyId = candidate?.partyId;
    if (selectedPartyId == null && _parties.isNotEmpty) {
      selectedPartyId = _parties.first.partyId;
    }

    bool hasCriminalRecord = candidate?.criminalRecord ?? false;
    String gender = candidate?.gender ?? 'Male';
    String nominationStatus = candidate?.nominationFormStatus ?? 'Submitted';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Candidate' : 'New Candidate Nomination'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Basic Information', style: TextStyle(fontWeight: FontWeight.bold)),
                const Divider(),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full Legal Name'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: gender,
                  items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (v) => setDialogState(() => gender = v!),
                  decoration: const InputDecoration(labelText: 'Gender'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qualificationController,
                  decoration: const InputDecoration(labelText: 'Educational Qualification'),
                ),
                const SizedBox(height: 24),
                
                const Text('Political Affiliation', style: TextStyle(fontWeight: FontWeight.bold)),
                const Divider(),
                DropdownButtonFormField<String>(
                  value: selectedPartyId,
                  items: _parties.map((p) => DropdownMenuItem(value: p.partyId, child: Text(p.partyName))).toList(),
                  onChanged: (v) => setDialogState(() => selectedPartyId = v),
                  decoration: const InputDecoration(labelText: 'Select Party'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: wardController,
                  decoration: const InputDecoration(labelText: 'Ward Number (e.g. Ward 1)'),
                ),
                const SizedBox(height: 24),

                const Text('Verification & Compliance', style: TextStyle(fontWeight: FontWeight.bold)),
                const Divider(),
                TextField(
                  controller: aadharController,
                  decoration: const InputDecoration(labelText: 'Aadhar Number (Encrypted)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: panController,
                  decoration: const InputDecoration(labelText: 'PAN Number'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: assetController,
                  decoration: const InputDecoration(labelText: 'Total Assets Declared (₹)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email Address'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Criminal Record?'),
                  value: hasCriminalRecord,
                  onChanged: (v) => setDialogState(() => hasCriminalRecord = v),
                ),
                if (hasCriminalRecord)
                  TextField(
                    controller: criminalDetailsController,
                    decoration: const InputDecoration(labelText: 'Criminal Record Details'),
                    maxLines: 2,
                  ),
                const SizedBox(height: 12),
                if (isEditing)
                  DropdownButtonFormField<String>(
                    value: nominationStatus,
                    items: ['Submitted', 'Accepted', 'Rejected']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setDialogState(() => nominationStatus = v!),
                    decoration: const InputDecoration(labelText: 'Nomination Form Status'),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || selectedPartyId == null || _selectedElection == null) return;

                final selectedParty = _parties.firstWhere((p) => p.partyId == selectedPartyId);

                final data = {
                  'candidateName': nameController.text,
                  'partyId': selectedPartyId,
                  'partySymbol': selectedParty.partySymbol,
                  'ward': wardController.text,
                  'gender': gender,
                  'qualification': qualificationController.text,
                  'aadharNumber': aadharController.text,
                  'panNumber': panController.text,
                  'assetValue': assetController.text,
                  'phone': phoneController.text,
                  'email': emailController.text,
                  'criminalRecord': hasCriminalRecord,
                  'criminalDetails': criminalDetailsController.text,
                  'nominationFormStatus': nominationStatus,
                  'nomineeStatus': nominationStatus == 'Accepted' ? 'Eligible' : (nominationStatus == 'Rejected' ? 'Ineligible' : 'Pending'),
                  'status': nominationStatus == 'Accepted' ? 'Active' : 'Inactive',
                  'voteCount': candidate?.voteCount ?? 0,
                  'electionId': _selectedElection!.uid,
                };

                if (isEditing) {
                  await _firestoreService.updateCandidate(candidate!.id, data);
                } else {
                  await _firestoreService.addCandidate(_selectedElection!.uid, data);
                }

                if (mounted) Navigator.pop(context);
              },
              child: Text(isEditing ? 'Update' : 'Submit Nomination'),
            )
          ],
        ),
      ),
    );
  }

  void _showScrutinyDialog(Candidate candidate) {
    String selectedStatus = candidate.nominationFormStatus ?? 'Submitted';
    final reasonController = TextEditingController(text: candidate.disqualificationReason ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Nomination Scrutiny: ${candidate.candidateName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Review eligibility based on Municipal Corporation regulations.'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                items: ['Submitted', 'Accepted', 'Rejected']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setDialogState(() => selectedStatus = v!),
                decoration: const InputDecoration(labelText: 'Final Decision'),
              ),
              if (selectedStatus == 'Rejected')
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(labelText: 'Reason for Disqualification'),
                  maxLines: 2,
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await _firestoreService.markCandidateEligible(
                  candidate.id, 
                  selectedStatus == 'Accepted',
                  reason: selectedStatus == 'Rejected' ? reasonController.text : null
                );
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Save Decision'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCandidate(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Candidate'),
        content: const Text('Are you sure you want to remove this candidate? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _firestoreService.deleteCandidate(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage District Candidates'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: _selectedElection == null || _parties.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showAddEditDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Candidate'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<Election>(
              value: _selectedElection,
              items: _elections.map((e) => DropdownMenuItem(value: e, child: Text(e.title))).toList(),
              onChanged: (e) => setState(() => _selectedElection = e),
              decoration: const InputDecoration(labelText: 'Select Election'),
            ),
          ),
          Expanded(
            child: _selectedElection == null
                ? const Center(child: Text("Select an election to manage candidates"))
                : StreamBuilder<List<Candidate>>(
                    stream: _firestoreService.getCandidatesStream(_selectedElection!.uid),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) return const Center(child: Text('Error loading candidates'));
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                      final candidates = snapshot.data!;
                      if (candidates.isEmpty) return const Center(child: Text('No nominations recorded for this election.'));

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: candidates.length,
                        itemBuilder: (_, index) {
                          final c = candidates[index];
                          final party = _parties.firstWhere(
                            (p) => p.partyId == c.partyId, 
                            orElse: () => Party(partyId: '', partyName: 'Independent', partyShortCode: 'IND', partyColor: '#757575', partySymbol: '', createdDate: DateTime.now(), updatedDate: DateTime.now(), status: 'Active')
                          );

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Color(int.parse(party.partyColor.replaceAll('#', '0xFF'))),
                                child: Text(party.partyShortCode.isNotEmpty ? party.partyShortCode[0] : '?', style: const TextStyle(color: Colors.white)),
                              ),
                              title: Text(c.candidateName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Party: ${party.partyName} | Ward: ${c.ward}\nNomination: ${c.nominationFormStatus}'),
                              isThreeLine: true,
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showAddEditDialog(c);
                                  } else if (value == 'scrutiny') {
                                    _showScrutinyDialog(c);
                                  } else {
                                    _deleteCandidate(c.id);
                                  }
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(value: 'edit', child: Text('Edit Candidate')),
                                  const PopupMenuItem(value: 'scrutiny', child: Text('Scrutiny Workflow')),
                                  const PopupMenuItem(value: 'delete', child: Text('Remove Nomination', style: TextStyle(color: AppColors.error))),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }

  void debug() {
    debugPrint('\x1B[34m'
        'lib/admin/manage_candidates.dart: executed'
        '\x1B[0m');
  }
}
