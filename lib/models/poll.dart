// lib/models/poll.dart
// Poll and PollOption models for event/society polls

class Poll {
  final String id;
  final String question;
  final String? eventId;
  final String? societyId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? endsAt;
  final bool isActive;
  final bool allowMultiple;
  final List<PollOption> options;

  // Computed
  int get totalVotes => options.fold(0, (sum, opt) => sum + opt.voteCount);

  Poll({
    required this.id,
    required this.question,
    this.eventId,
    this.societyId,
    required this.createdBy,
    required this.createdAt,
    this.endsAt,
    this.isActive = true,
    this.allowMultiple = false,
    this.options = const [],
  });

  factory Poll.fromMap(Map<String, dynamic> map, {List<PollOption>? options}) {
    return Poll(
      id: map['id'] ?? '',
      question: map['question'] ?? '',
      eventId: map['event_id'],
      societyId: map['society_id'],
      createdBy: map['created_by'] ?? '',
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      endsAt: map['ends_at'] != null ? DateTime.parse(map['ends_at']) : null,
      isActive: map['is_active'] ?? true,
      allowMultiple: map['allow_multiple'] ?? false,
      options: options ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'event_id': eventId,
      'society_id': societyId,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'ends_at': endsAt?.toIso8601String(),
      'is_active': isActive,
      'allow_multiple': allowMultiple,
    };
  }

  bool get isExpired => endsAt != null && DateTime.now().isAfter(endsAt!);
  bool get canVote => isActive && !isExpired;
}

class PollOption {
  final String id;
  final String pollId;
  final String text;
  final int voteCount;
  final bool isUserVote; // Whether current user voted for this

  PollOption({
    required this.id,
    required this.pollId,
    required this.text,
    this.voteCount = 0,
    this.isUserVote = false,
  });

  factory PollOption.fromMap(Map<String, dynamic> map, {bool isUserVote = false}) {
    return PollOption(
      id: map['id'] ?? '',
      pollId: map['poll_id'] ?? '',
      text: map['text'] ?? map['option_text'] ?? '',
      voteCount: map['vote_count'] ?? 0,
      isUserVote: isUserVote,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'poll_id': pollId,
      'text': text,
    };
  }

  double percentageOf(int totalVotes) {
    if (totalVotes == 0) return 0;
    return (voteCount / totalVotes) * 100;
  }
}

class PollVote {
  final String id;
  final String pollId;
  final String optionId;
  final String userId;
  final DateTime votedAt;

  PollVote({
    required this.id,
    required this.pollId,
    required this.optionId,
    required this.userId,
    required this.votedAt,
  });

  factory PollVote.fromMap(Map<String, dynamic> map) {
    return PollVote(
      id: map['id'] ?? '',
      pollId: map['poll_id'] ?? '',
      optionId: map['option_id'] ?? '',
      userId: map['user_id'] ?? '',
      votedAt: DateTime.parse(map['voted_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'poll_id': pollId,
      'option_id': optionId,
      'user_id': userId,
      'voted_at': votedAt.toIso8601String(),
    };
  }
}
