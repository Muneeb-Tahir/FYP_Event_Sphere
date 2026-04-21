import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_theme.dart';
import '../services/poll_service.dart';
import '../providers/auth_provider.dart';

class PollPageRedesigned extends ConsumerStatefulWidget {
  const PollPageRedesigned({super.key});

  @override
  ConsumerState<PollPageRedesigned> createState() => _PollPageRedesignedState();
}

class _PollPageRedesignedState extends ConsumerState<PollPageRedesigned> {
  String? selectedOption;
  bool _isLoading = false;
  bool _isSubmitting = false;
  List<Poll> _polls = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPolls();
  }

  // ------------------------- LOAD POLLS -------------------------
  Future<void> _loadPolls() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final polls = await PollService.getActivePolls();
      if (mounted) {
        setState(() {
          _polls = polls;
          _isLoading = false;
        });
      }
    } catch (e) {
      _handleError('Failed to load polls: ${e.toString()}');
    }
  }

  // ------------------------- REFRESH POLLS -------------------------
  Future<void> _refreshPolls() async {
    await _loadPolls();
  }

  // ------------------------- SUBMIT VOTE -------------------------
  Future<void> _submitVote(String pollId) async {
    if (selectedOption == null) {
      _showSnackBar('Please select an option first', isError: true);
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) {
      _showSnackBar('Please login to vote', isError: true);
      return;
    }

    // Check if already voted
    if (PollService.hasVoted(user.id, pollId)) {
      _showSnackBar('You have already voted on this poll', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await PollService.submitVote(
        pollId: pollId,
        userId: user.id,
        selectedOption: selectedOption!,
      );

      _showSnackBar('Vote submitted successfully!');
      await _refreshPolls();
      setState(() => selectedOption = null);
    } catch (e) {
      _showSnackBar('Failed to submit vote: ${e.toString()}', isError: true);
    }

    setState(() => _isSubmitting = false);
  }

  // ------------------------- SELECT OPTION -------------------------
  void _selectOption(String option, String pollId) {
    final user = ref.read(currentUserProvider);
    if (user != null && PollService.hasVoted(user.id, pollId)) {
      _showSnackBar('You have already voted on this poll');
      return;
    }
    setState(() => selectedOption = option);
  }

  // ------------------------- CHECK IF VOTED -------------------------
  bool _hasUserVoted(String pollId) {
    final user = ref.read(currentUserProvider);
    if (user == null) return false;
    return PollService.hasVoted(user.id, pollId);
  }

  // ------------------------- GET USER VOTE -------------------------
  String? _getUserVote(String pollId) {
    final user = ref.read(currentUserProvider);
    if (user == null) return null;
    return PollService.getUserVote(user.id, pollId);
  }

  // ------------------------- HANDLE ERROR -------------------------
  void _handleError(String message) {
    if (mounted) {
      setState(() {
        _error = message;
        _isLoading = false;
      });
    }
  }

  // ------------------------- SHOW SNACKBAR -------------------------
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.dangerColor : AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ------------------------- CALCULATE PERCENTAGE -------------------------
  double _calculatePercentage(int votes, int totalVotes) {
    if (totalVotes == 0) return 0;
    return (votes / totalVotes) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B2E),
        elevation: 0,
        title: const Text(
          'Polls',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isLoading ? null : _refreshPolls,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF9D4EDD)));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPolls,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9D4EDD)),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (_polls.isEmpty) {
      return const Center(
        child: Text('No active polls', style: TextStyle(color: Color(0xFFB8A9C9))),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshPolls,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _polls.length,
        itemBuilder: (context, index) => _buildPollCard(_polls[index]),
      ),
    );
  }

  Widget _buildPollCard(Poll poll) {
    final hasVoted = _hasUserVoted(poll.id);
    final userVote = _getUserVote(poll.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B2E),
        borderRadius: BorderRadius.circular(AppTheme.cornerRadiusLarge),
        border: Border.all(color: const Color(0xFF3D3557).withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            poll.question,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${poll.totalVotes} votes so far',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFB8A9C9),
            ),
          ),
          if (hasVoted)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '✓ You voted',
                style: TextStyle(fontSize: 11, color: Colors.green),
              ),
            ),
          const SizedBox(height: 24),
          ...poll.options.entries.map((entry) {
            final percentage = _calculatePercentage(entry.value, poll.totalVotes);
            final isSelected = selectedOption == entry.key;
            final isUserVote = userVote == entry.key;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: hasVoted ? null : () => _selectOption(entry.key, poll.id),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected || isUserVote
                        ? const Color(0xFF9D4EDD).withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected || isUserVote
                          ? const Color(0xFF9D4EDD)
                          : const Color(0xFF3D3557),
                      width: isSelected || isUserVote ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              entry.key,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isUserVote
                                    ? const Color(0xFF9D4EDD)
                                    : Colors.white,
                              ),
                            ),
                          ),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9D4EDD),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Stack(
                          children: [
                            Container(
                              height: 12,
                              color: const Color(0xFF3D3557),
                            ),
                            FractionallySizedBox(
                              widthFactor: percentage / 100,
                              child: Container(
                                height: 12,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF8B5CF6),
                                      Color(0xFFEC4899)
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${entry.value} votes',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFB8A9C9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          if (!hasVoted && selectedOption != null)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF16A34A)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _isSubmitting ? null : () => _submitVote(poll.id),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Submit Vote',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

