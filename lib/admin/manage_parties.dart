import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/firestore_service.dart';
import '../models/party.dart';

class ManagePartiesPage extends StatefulWidget {
  const ManagePartiesPage({super.key});

  @override
  State<ManagePartiesPage> createState() => _ManagePartiesPageState();
}

class _ManagePartiesPageState extends State<ManagePartiesPage> {
  final _firestoreService = FirestoreService();
  bool _isLoading = false;

  void _showAddEditDialog([Party? party]) {
    final isEditing = party != null;
    final nameController = TextEditingController(text: party?.partyName ?? '');
    final shortCodeController = TextEditingController(text: party?.partyShortCode ?? '');
    final symbolController = TextEditingController(text: party?.partySymbol ?? '');
    final colorController = TextEditingController(text: party?.partyColor ?? '#FF9933');
    
    bool isNational = party?.isNationalParty ?? false;
    bool isState = party?.isStateParty ?? false;
    bool isRecognized = party?.isRecognizedParty ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Party' : 'Add New Party'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Party Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: shortCodeController,
                  decoration: const InputDecoration(labelText: 'Short Code (e.g. BJP)'),
                  maxLength: 10,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: symbolController,
                  decoration: const InputDecoration(labelText: 'Election Symbol'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: colorController,
                  decoration: const InputDecoration(labelText: 'Party Color (Hex)'),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('National Party'),
                  value: isNational,
                  onChanged: (val) => setDialogState(() => isNational = val),
                ),
                SwitchListTile(
                  title: const Text('State Party'),
                  value: isState,
                  onChanged: (val) => setDialogState(() => isState = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || shortCodeController.text.isEmpty) return;

                final newParty = Party(
                  partyId: party?.partyId ?? Party.generatePartyId(shortCodeController.text),
                  partyName: nameController.text,
                  partyShortCode: shortCodeController.text.toUpperCase(),
                  partyColor: colorController.text,
                  partySymbol: symbolController.text,
                  isNationalParty: isNational,
                  isStateParty: isState,
                  isRecognizedParty: isRecognized,
                  createdDate: party?.createdDate ?? DateTime.now(),
                  updatedDate: DateTime.now(),
                  status: party?.status ?? 'Active',
                );

                if (isEditing) {
                  await _firestoreService.updateParty(newParty.partyId, newParty.toMap());
                } else {
                  await _firestoreService.createParty(newParty);
                }
                
                if (mounted) Navigator.pop(context);
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
        title: const Text('Manage Parties'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Party>>(
        stream: _firestoreService.getPartiesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No parties registered.'));
          }

          final parties = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: parties.length,
            itemBuilder: (context, index) {
              final party = parties[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(int.parse(party.partyColor.replaceAll('#', '0xFF'))),
                    child: Text(party.partyShortCode[0], style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(party.partyName),
                  subtitle: Text('Code: ${party.partyShortCode} | Symbol: ${party.partySymbol}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showAddEditDialog(party),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppColors.error),
                        onPressed: () => _firestoreService.deleteParty(party.partyId),
                      ),
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
}
