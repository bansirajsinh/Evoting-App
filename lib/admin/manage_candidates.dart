import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/firestore_service.dart';
import '../models/election.dart';
import '../models/candidate.dart';


class ManageCandidatesPage extends StatefulWidget {
  const ManageCandidatesPage({super.key});

  @override
  State<ManageCandidatesPage> createState() => _ManageCandidatesPageState();
}

class _ManageCandidatesPageState extends State<ManageCandidatesPage> {
  final _firestoreService = FirestoreService();

  List<Election> _elections = [];
  Election? _selectedElection;



  final List<String> _symbols = [
    '🌸','✋','🌾','🏠','⭐','🌻','🔔','🎯','🌈','🦋'
  ];

  @override
  void initState() {
    super.initState();
    _loadElections();
    debug();
  }

  Future<void> _loadElections() async {
    debugPrint('\x1B[32m'
        'lib/admin/manage_candidates.dart: _loadElections() executed'
        '\x1B[0m');

    try {
      final elections = await _firestoreService.getElections();

      setState(() {
        _elections = elections;

        // ✅ auto select first election
        if (elections.isNotEmpty) {
          _selectedElection = elections.first;
        }
      });

    } catch (e) {
      debugPrint('Error loading elections: $e');
    }
  }


  // FIX: Changed parameter type from Map<String, dynamic>? to Candidate?
  void _showAddEditDialog([Candidate? candidate]) {
    debugPrint('\x1B[32m'
    'lib/admin/manage_candidates.dart: _showAddEditDialog() executed'
    '\x1B[0m');
    final isEditing = candidate != null;

    // FIX: Access candidate properties directly instead of map syntax
    final nameController =
    TextEditingController(text: candidate?.name ?? '');
    final partyController =
    TextEditingController(text: candidate?.party ?? '');
    final manifestoController =
    TextEditingController(text: candidate?.manifesto ?? '');

    String selectedSymbol = candidate?.symbol ?? _symbols.first;

    String selectedConstituency = candidate?.constituency ??(_selectedElection?.constituencies.first ?? 'General');

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Candidate' : 'Add Candidate'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: partyController,
                  decoration: const InputDecoration(labelText: 'Party'),
                ),
                const SizedBox(height: 12),

                // DropdownButtonFormField<String>(
                //   initialValue: selectedConstituency,
                //   items: _selectedElection!.constituencies
                //       .map((c) =>
                //       DropdownMenuItem(value: c, child: Text(c)))
                //       .toList(),
                //   onChanged: (v) =>
                //       setDialogState(() => selectedConstituency = v!),
                //   decoration:
                //   const InputDecoration(labelText: 'Constituency'),
                // ),
                // const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  children: _symbols.map((symbol) {
                    final isSelected = symbol == selectedSymbol;
                    return GestureDetector(
                      onTap: () =>
                          setDialogState(() => selectedSymbol = symbol),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.transparent),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(symbol,
                            style:
                            const TextStyle(fontSize: 22)),
                      ),
                    );
                  }).toList(),
                ),
         const SizedBox(height: 12),
                
                TextField(
                  controller: manifestoController,
                  maxLines: 3,
                  decoration:
                  const InputDecoration(labelText: 'Manifesto'),
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
                if (nameController.text.isEmpty ||
                    partyController.text.isEmpty) return;

                if (isEditing) {
                  // FIX: Access candidate.id directly
                  await _firestoreService.updateCandidate(
                    candidate.id,
                    {
                      'name': nameController.text,
                      'party': partyController.text,
                      'symbol': selectedSymbol,
                      'constituency': selectedConstituency,
                      'manifesto': manifestoController.text,
                    },
                  );
                } else {
                  // FIX: Pass electionId as first argument, data as second
                  await _firestoreService.addCandidate(
                    _selectedElection!.id,
                    {
                      'name': nameController.text,
                      'party': partyController.text,
                      'symbol': selectedSymbol,
                      'constituency': selectedConstituency,
                      'manifesto': manifestoController.text,
                      'voteCount': 0,
                    },
                  );
                }

                Navigator.pop(context);
                  
              },
              child: Text(isEditing ? 'Update' : 'Add'),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCandidate(String id) async {
    debugPrint('\x1B[32m'
    'lib/admin/manage_candidates.dart: _deleteCandidate() executed'
    '\x1B[0m');
    await _firestoreService.deleteCandidate(id);
      
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Candidates'),
        backgroundColor: AppColors.primaryDark,
      ),
      floatingActionButton: _selectedElection == null
          ? null
          : FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<Election>(
              initialValue: _selectedElection,
              items: _elections
                  .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e.title),
              ))
                  .toList(),
              onChanged: (e) {
                setState(() => _selectedElection = e);
                  
              },
              decoration:
              const InputDecoration(labelText: 'Election'),
            ),
          ),
          Expanded(
            child: _selectedElection == null
                ? const Center(child: Text("Select an election"))
                : StreamBuilder<List<Candidate>>(
                    stream: _firestoreService
                        .getCandidatesStream(_selectedElection!.id),
                    builder: (context, snapshot) {

                      // 🔴 ERROR
                      if (snapshot.hasError) {
                        return const Center(child: Text('Error loading candidates'));
                      }

                      // ⏳ LOADING
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final candidates = snapshot.data!;

                      // 📭 EMPTY
                      if (candidates.isEmpty) {
                        return const Center(child: Text('No Candidates'));
                      }

                      // ✅ THIS IS WHERE YOUR CODE GOES
                      return ListView.builder(
                        itemCount: candidates.length,
                        itemBuilder: (_, index) {
                          final c = candidates[index];

                          return ListTile(
                            leading: Text(
                              c.symbol,
                              style: const TextStyle(fontSize: 24),
                            ),
                            title: Text(c.name),
                            subtitle: Text(c.party),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showAddEditDialog(c);
                                } else {
                                  _deleteCandidate(c.id);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'edit', child: Text('Edit')),
                                PopupMenuItem(value: 'delete', child: Text('Delete')),
                              ],
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
