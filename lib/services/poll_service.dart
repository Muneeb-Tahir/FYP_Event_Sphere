// lib/services/poll_service.dart
// MOCK SERVICE - Replace with Firebase/Supabase in production

import 'dart:async';

class Poll {
  final String id;
  final String question;
  final Map<String, int> options; // option text -> vote count
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String? eventId;
  final bool isActive;

  Poll({
    required this.id,
    required this.question,
    required this.options,
    required this.createdAt,
    this.expiresAt,
    this.eventId,
    this.isActive = true,
  });

  int get totalVotes => options.values.fold(0, (sum, count) => sum + count);
}

class PollService {
  static final List<Poll> _polls = [
    Poll(
      id: 'poll1',
      question: 'What type of events do you prefer?',
      options: {'Online Events': 45, 'Offline Events': 60, 'Hybrid Events': 45},
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Poll(
      id: 'poll2',
      question: 'Best day for Tech Workshop?',
      options: {'Monday': 12, 'Wednesday': 28, 'Friday': 35},
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      eventId: 'event1',
    ),
  ];

  // Track user votes: {pollId: selectedOption}
  static final Map<String, Map<String, String>> _userVotes = {};

  // ------------------------- STREAM POLLS -------------------------
  static Stream<List<Poll>> getPollsStream() async* {
    yield List.from(_polls);
    await for (final _ in Stream.periodic(const Duration(seconds: 3))) {
      yield List.from(_polls);
    }
  }

  // ------------------------- GET ACTIVE POLLS -------------------------
  static Future<List<Poll>> getActivePolls() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _polls.where((p) => p.isActive).toList();
  }

  // ------------------------- GET POLL BY ID -------------------------
  static Future<Poll?> getPoll(String pollId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _polls.firstWhere((p) => p.id == pollId);
    } catch (_) {
      return null;
    }
  }

  // ------------------------- SUBMIT VOTE -------------------------
  static Future<void> submitVote({
    required String pollId,
    required String userId,
    required String selectedOption,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Check if user already voted
    if (_userVotes[userId]?.containsKey(pollId) ?? false) {
      throw Exception('You have already voted on this poll');
    }

    // Find poll and update vote count
    final pollIndex = _polls.indexWhere((p) => p.id == pollId);
    if (pollIndex == -1) throw Exception('Poll not found');

    final poll = _polls[pollIndex];
    if (!poll.options.containsKey(selectedOption)) {
      throw Exception('Invalid option');
    }

    // Update vote count
    final updatedOptions = Map<String, int>.from(poll.options);
    updatedOptions[selectedOption] = (updatedOptions[selectedOption] ?? 0) + 1;

    _polls[pollIndex] = Poll(
      id: poll.id,
      question: poll.question,
      options: updatedOptions,
      createdAt: poll.createdAt,
      expiresAt: poll.expiresAt,
      eventId: poll.eventId,
      isActive: poll.isActive,
    );

    // Track user vote
    _userVotes[userId] ??= {};
    _userVotes[userId]![pollId] = selectedOption;
  }

  // ------------------------- CHECK IF VOTED -------------------------
  static bool hasVoted(String userId, String pollId) {
    return _userVotes[userId]?.containsKey(pollId) ?? false;
  }

  // ------------------------- GET USER VOTE -------------------------
  static String? getUserVote(String userId, String pollId) {
    return _userVotes[userId]?[pollId];
  }

  // ------------------------- CREATE POLL -------------------------
  static Future<void> createPoll({
    required String question,
    required List<String> options,
    String? eventId,
    DateTime? expiresAt,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final optionsMap = <String, int>{};
    for (final opt in options) {
      optionsMap[opt] = 0;
    }

    _polls.insert(0, Poll(
      id: 'poll_${DateTime.now().millisecondsSinceEpoch}',
      question: question,
      options: optionsMap,
      createdAt: DateTime.now(),
      expiresAt: expiresAt,
      eventId: eventId,
    ));
  }

  // ------------------------- DELETE POLL -------------------------
  static Future<void> deletePoll(String pollId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _polls.removeWhere((p) => p.id == pollId);
  }

  // ------------------------- CLOSE POLL -------------------------
  static Future<void> closePoll(String pollId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _polls.indexWhere((p) => p.id == pollId);
    if (index != -1) {
      final poll = _polls[index];
      _polls[index] = Poll(
        id: poll.id,
        question: poll.question,
        options: poll.options,
        createdAt: poll.createdAt,
        expiresAt: poll.expiresAt,
        eventId: poll.eventId,
        isActive: false,
      );
    }
  }
}
