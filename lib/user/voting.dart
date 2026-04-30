import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/blockchain_service.dart';
import 'confirmation.dart';
import '../models/election.dart';
import '../models/candidate.dart';
import '../models/vote.dart';

class VotingPage extends StatefulWidget {
  final List<Election> elections;

  const VotingPage({super.key, required this.elections});

  @override
  State<VotingPage> createState() => _VotingPageState();
}

class _VotingPageState extends State<VotingPage> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _blockchainService = BlockchainService();

  Election? _selectedElection;
  List<Candidate> _candidates = [];
  Candidate? _selectedCandidate;
  bool _isLoading = false;
  bool _hasVoted = false;

  @override
  void didUpdateWidget(covariant VotingPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.elections != oldWidget.elections &&
        widget.elections.isNotEmpty) {
      _selectElection(widget.elections.first);
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.elections.isNotEmpty) {
      _selectElection(widget.elections.first);
    }
    debug();
  }

  Future<void> _selectElection(Election election) async {
    debugPrint('\x1B[32m'
        'lib/user/voting.dart: _selectElection() executed'
        '\x1B[0m');

    setState(() {
      _selectedElection = election;
      _selectedCandidate = null;
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;

      if (user != null) {
        final voterId = user.voterId;
        _hasVoted = await _firestoreService.hasVoted(voterId, election.uid);
        
        // DISTRICT ELECTION FIX: Filter candidates by user's ward
        final candidates = await _firestoreService.getCandidatesByWard(election.uid, user.ward);
        setState(() => _candidates = candidates);
      } else {
        final candidates = await _firestoreService.getCandidates(election.uid);
        setState(() => _candidates = candidates);
      }
    } catch (e) {
      debugPrint('Error loading candidates: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _castVote() async {
    debugPrint('\x1B[32m''lib/user/voting.dart: _castVote() executed''\x1B[0m');

    if (_selectedCandidate == null || _selectedElection == null) return;

    final confirmed = await _showConfirmationDialog();
    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('User not logged in');
      
      final voterId = user.voterId;
      final voterHash = _blockchainService.generateVoterHash(voterId);
      final candidateHash = _blockchainService.generateCandidateHash(_selectedCandidate!.id);

      final transaction = await _blockchainService.castVote(
        voterHash: voterHash,
        candidateHash: candidateHash,
        electionId: _selectedElection!.uid,
      );

      if (transaction != null) {
        final voteHash = _blockchainService.generateVoteHash(
          voterId: user.voterId,
          candidateId: _selectedCandidate!.id,
          electionId: _selectedElection!.uid,
          timestamp: DateTime.now(),
        );

        await _firestoreService.recordVote(Vote(
          id: '',
          electionId: _selectedElection!.uid,
          voterId: user.voterId,
          voterHash: voterHash,
          candidateId: _selectedCandidate!.id,
          voteHash: voteHash,
          transactionHash: transaction.transactionHash,
          timestamp: DateTime.now(),
          blockHash: transaction.blockHash,
          previousBlockHash: "",
          blockNumber: transaction.blockNumber,
          accountAddress: transaction.from,
        ));

        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ConfirmationPage(
              election: _selectedElection!,
              candidate: _selectedCandidate!,
              transactionHash: transaction.transactionHash,
              blockNumber: transaction.blockNumber,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Voting failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _showConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Your Vote'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('You are voting for Ward: ${_authService.currentUser?.ward ?? "N/A"}'),
                const SizedBox(height: 8),
                const Text('Selected Candidate:'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: Text(
                          _selectedCandidate!.candidateName.isNotEmpty ? _selectedCandidate!.candidateName[0] : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedCandidate!.candidateName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _selectedCandidate!.partyId,
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'This action cannot be undone. Your vote will be recorded on the blockchain.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirm Vote'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.elections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.how_to_vote_outlined,
              size: 80,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Active Elections',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 8),
            const Text(
              'There are no elections available for voting right now',
              style: AppTextStyles.body2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (widget.elections.length > 1)
          Container(
            padding: const EdgeInsets.all(AppDimens.paddingMedium),
            child: DropdownButtonFormField<Election>(
              value: _selectedElection,
              decoration: InputDecoration(
                labelText: 'Select Election',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.borderRadius),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              items: widget.elections.map((election) {
                return DropdownMenuItem(
                  value: election,
                  child: Text(election.title, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (election) {
                if (election != null) _selectElection(election);
              },
            ),
          ),
        if (_hasVoted)
          Container(
            margin: const EdgeInsets.all(AppDimens.paddingMedium),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimens.borderRadius),
              border: Border.all(color: AppColors.success),
            ),
            child: Row(
              children: const [
                Icon(Icons.check_circle, color: AppColors.success),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You have already voted in this election',
                    style: TextStyle(color: AppColors.success),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _candidates.isEmpty
                  ? Center(
                      child: Text('No candidates found for Ward: ${_authService.currentUser?.ward ?? "N/A"}'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppDimens.paddingMedium),
                      itemCount: _candidates.length,
                      itemBuilder: (context, index) {
                        final candidate = _candidates[index];
                        final isSelected = _selectedCandidate?.id == candidate.id;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppDimens.borderRadius),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : Colors.transparent,
                              width: 2,
                            ),
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
                              onTap: _hasVoted
                                  ? null
                                  : () => setState(() => _selectedCandidate = candidate),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundColor: AppColors.primaryLight.withOpacity(0.1),
                                      child: Text(
                                        candidate.candidateName.isNotEmpty ? candidate.candidateName[0] : '?',
                                        style: const TextStyle(fontSize: 24, color: AppColors.primary),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            candidate.candidateName,
                                            style: AppTextStyles.heading3,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            candidate.partyId,
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            'Ward: ${candidate.ward}',
                                            style: AppTextStyles.caption,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      )
                                    else
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          border: Border.all(color: AppColors.divider, width: 2),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
        if (!_hasVoted && _selectedCandidate != null)
          Container(
            padding: const EdgeInsets.all(AppDimens.paddingMedium),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: AppDimens.buttonHeight,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _castVote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.borderRadius),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Cast Your Vote', style: AppTextStyles.button),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void debug() {
    debugPrint('\x1B[34m''lib/user/voting.dart: executed''\x1B[0m');
  }
}
