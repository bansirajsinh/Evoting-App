import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/firestore_service.dart';
import '../services/blockchain_service.dart';
import '../models/election.dart';

class ManageElectionsPage extends StatefulWidget {
  const ManageElectionsPage({super.key});

  @override
  State<ManageElectionsPage> createState() => _ManageElectionsPageState();
}

class _ManageElectionsPageState extends State<ManageElectionsPage> {
  final _firestoreService = FirestoreService();
  final BlockchainService _blockchainService = BlockchainService();

  bool _isLoading = false;

  final List<String> _districts = [
    'AHM', 'AMR', 'ANA', 'BAN', 'BRD', 'BHV', 'BOT', 'CHA', 'DAH', 'DNG', 
    'GDH', 'GIR', 'JAM', 'JUN', 'KAC', 'KAI', 'MEH', 'MOR', 'NAR', 'NAV', 
    'PAN', 'PAT', 'POR', 'RAJ', 'SAB', 'SRT', 'TAP', 'VDR', 'VAL'
  ];

  final List<String> _electionTypes = ['MC', 'MB', 'ZP', 'TP', 'GP'];
  final Map<String, String> _typeNames = {
    'MC': 'Municipal Corporation',
    'MB': 'Municipal Board',
    'ZP': 'Zilla Parishad',
    'TP': 'Taluka Panchayat',
    'GP': 'Gram Panchayat',
  };

  @override
  void initState() {
    super.initState();
    debug();
  }

  void _showAddEditDialog([Election? election]) {
    final isEditing = election != null;
    final titleController = TextEditingController(text: election?.title ?? '');
    final descController = TextEditingController(text: election?.description ?? '');
    final wardsController = TextEditingController(text: election?.totalWards.toString() ?? '');
    final notificationNumberController = TextEditingController(text: election?.electionCommissionNotification ?? '');

    String selectedDistrict = election?.district ?? 'AHM';
    String selectedType = election?.municipalityType ?? 'MC';
    int year = election?.pollingDate.year ?? DateTime.now().year;
    
    DateTime notificationDate = election?.notificationDate ?? DateTime.now();
    DateTime nominationStartDate = election?.nominationStartDate ?? DateTime.now().add(const Duration(days: 7));
    DateTime nominationEndDate = election?.nominationEndDate ?? DateTime.now().add(const Duration(days: 14));
    DateTime scrutinyDate = election?.scrutinyDate ?? DateTime.now().add(const Duration(days: 15));
    DateTime withdrawalDate = election?.withdrawalDate ?? DateTime.now().add(const Duration(days: 17));
    DateTime pollingDate = election?.pollingDate ?? DateTime.now().add(const Duration(days: 30));
    DateTime resultDate = election?.resultDate ?? DateTime.now().add(const Duration(days: 32));

    String status = election?.status ?? 'Notified';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit District Election' : 'Create District Election'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Election Title', hintText: 'e.g. Ahmedabad Municipal Election 2026'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedDistrict,
                        decoration: const InputDecoration(labelText: 'District Code'),
                        items: _districts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                        onChanged: (v) => setDialogState(() => selectedDistrict = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedType,
                        decoration: const InputDecoration(labelText: 'Type'),
                        items: _electionTypes.map((t) => DropdownMenuItem(value: t, child: Text(_typeNames[t]!))).toList(),
                        onChanged: (v) => setDialogState(() => selectedType = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: wardsController,
                  decoration: const InputDecoration(labelText: 'Total Wards'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notificationNumberController,
                  decoration: const InputDecoration(labelText: 'SEC Notification Number'),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('Polling Date'),
                  subtitle: Text(_formatDate(pollingDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: pollingDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (date != null) setDialogState(() => pollingDate = date);
                  },
                ),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: ['Notified', 'Nomination Open', 'Scrutiny', 'Withdrawal Open', 'Campaign Active', 'Polling', 'Counting', 'Completed']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setDialogState(() => status = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || wardsController.text.isEmpty) return;

                final electionId = Election.generateElectionCode(selectedDistrict, selectedType, pollingDate.year);
                
                final newElection = Election(
                  uid: election?.uid ?? '',
                  electionId: electionId,
                  title: titleController.text,
                  description: descController.text,
                  electionType: 'Municipal Election',
                  totalWards: int.parse(wardsController.text),
                  notificationDate: notificationDate,
                  nominationStartDate: nominationStartDate,
                  nominationEndDate: nominationEndDate,
                  scrutinyDate: scrutinyDate,
                  withdrawalDate: withdrawalDate,
                  pollingDate: pollingDate,
                  resultDate: resultDate,
                  status: status,
                  createdAt: election?.createdAt ?? DateTime.now(),
                  createdBy: 'admin',
                  district: selectedDistrict,
                  municipalityType: _typeNames[selectedType],
                  electionCommissionNotification: notificationNumberController.text,
                );

                setState(() => _isLoading = true);
                Navigator.pop(context);

                try {
                  if (isEditing) {
                    await _firestoreService.updateElection(newElection);
                  } else {
                    await _firestoreService.createElection(newElection);
                  }
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Election saved successfully'), backgroundColor: AppColors.success));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
                } finally {
                  setState(() => _isLoading = false);
                }
              },
              child: Text(isEditing ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage District Elections'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('New District Election'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : StreamBuilder<List<Election>>(
            stream: _firestoreService.getElectionsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('No elections found.'));

              final elections = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: elections.length,
                itemBuilder: (context, index) {
                  final e = elections[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(e.title, style: AppTextStyles.heading3),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Code: ${e.electionId} | District: ${e.district}'),
                          Text('Wards: ${e.totalWards} | Status: ${e.status}'),
                          Text('Polling: ${_formatDate(e.pollingDate)}'),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (val) {
                          if (val == 'edit') _showAddEditDialog(e);
                          if (val == 'delete') _firestoreService.deleteElection(e.uid);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
  void debug() => debugPrint('\x1B[34mManageElectionsPage executed\x1B[0m');
}
